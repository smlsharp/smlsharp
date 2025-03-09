@sml_check_flag=external local_unnamed_addr global i32
@_SML_gvarc86a8a57f9dc856e_UserErrorUtils=private global<{[4x i8],i32,[10x i8*]}><{[4x i8]zeroinitializer,i32 -1342177200,[10x i8*]zeroinitializer}>,align 8
@a=private unnamed_addr global[2x i64][i64 1,i64 sub(i64 ptrtoint(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i32 0,i32 2,i32 0)to i64),i64 ptrtoint([2x i64]*@a to i64))]
@_SML_ftabc86a8a57f9dc856e_UserErrorUtils=external global i8
@b=private unnamed_addr global i8 0
@_SMLZN14UserErrorUtils20initializeErrorQueueE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i32 0,i32 2,i32 0)
@_SMLZN14UserErrorUtils20getErrorsAndWarningsE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i32 0,i32 2,i32 1)
@_SMLZN14UserErrorUtils9getErrorsE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i32 0,i32 2,i32 2)
@_SMLZN14UserErrorUtils10isAnyErrorE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i32 0,i32 2,i32 3)
@_SMLZN14UserErrorUtils11getWarningsE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i32 0,i32 2,i32 4)
@_SMLZN14UserErrorUtils12enqueueErrorE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i32 0,i32 2,i32 5)
@_SMLZN14UserErrorUtils14enqueueWarningE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i32 0,i32 2,i32 6)
@_SMLZN14UserErrorUtils23checkSymbolDuplication_GE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i32 0,i32 2,i32 7)
@_SMLZN14UserErrorUtils22checkSymbolDuplicationE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i32 0,i32 2,i32 8)
@_SMLZN14UserErrorUtils27checkRecordLabelDuplicationE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i32 0,i32 2,i32 9)
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
declare void@_SML_main89b8631430c545af_Symbol()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_maina142c315f12317c0_RecordLabel()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_mainadeb402e3568875f_UserError_ppg()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_loaddaa180c1799f3810_Bool(i8*)local_unnamed_addr
declare void@_SML_load03d87556ec7f64b2_List(i8*)local_unnamed_addr
declare void@_SML_load89b8631430c545af_Symbol(i8*)local_unnamed_addr
declare void@_SML_loada142c315f12317c0_RecordLabel(i8*)local_unnamed_addr
declare void@_SML_loadadeb402e3568875f_UserError_ppg(i8*)local_unnamed_addr
define private void@_SML_tabbc86a8a57f9dc856e_UserErrorUtils()#2{
unreachable
}
define void@_SML_loadc86a8a57f9dc856e_UserErrorUtils(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@b,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@b,align 1
tail call void@_SML_loaddaa180c1799f3810_Bool(i8*%a)#0
tail call void@_SML_load03d87556ec7f64b2_List(i8*%a)#0
tail call void@_SML_load89b8631430c545af_Symbol(i8*%a)#0
tail call void@_SML_loada142c315f12317c0_RecordLabel(i8*%a)#0
tail call void@_SML_loadadeb402e3568875f_UserError_ppg(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbc86a8a57f9dc856e_UserErrorUtils,i8*@_SML_ftabc86a8a57f9dc856e_UserErrorUtils,i8*bitcast([2x i64]*@a to i8*))#0
ret void
}
define void@_SML_mainc86a8a57f9dc856e_UserErrorUtils()local_unnamed_addr#1 gc"smlsharp"personality i32(...)*@sml_personality{
%a=alloca[3x i8*],align 8
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
%l=load i8,i8*@b,align 1
%m=and i8%l,2
%n=icmp eq i8%m,0
br i1%n,label%p,label%o
o:
ret void
p:
store i8 3,i8*@b,align 1
tail call void@_SML_maindaa180c1799f3810_Bool()#1
tail call void@_SML_main03d87556ec7f64b2_List()#1
tail call void@_SML_main89b8631430c545af_Symbol()#1
tail call void@_SML_maina142c315f12317c0_RecordLabel()#1
tail call void@_SML_mainadeb402e3568875f_UserError_ppg()#1
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
%q=bitcast[3x i8*]*%a to i8*
call void@sml_start(i8*inreg%q)#0
%r=load atomic i32,i32*@sml_check_flag unordered,align 4
%s=icmp eq i32%r,0
br i1%s,label%u,label%t
t:
invoke void@sml_check(i32 inreg%r)
to label%u unwind label%cy
u:
%v=invoke fastcc i8*@_SMLFN9UserError11createQueueE(i32 inreg 0)
to label%w unwind label%cy
w:
store i8*%v,i8**%b,align 8
%x=call i8*@sml_alloc(i32 inreg 12)#0
%y=getelementptr inbounds i8,i8*%x,i64 -4
%z=bitcast i8*%y to i32*
store i32 1342177288,i32*%z,align 4
store i8*%x,i8**%c,align 8
%A=load i8*,i8**%b,align 8
%B=bitcast i8*%x to i8**
store i8*%A,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%x,i64 8
%D=bitcast i8*%C to i32*
store i32 1,i32*%D,align 4
%E=call i8*@sml_alloc(i32 inreg 28)#0
%F=getelementptr inbounds i8,i8*%E,i64 -4
%G=bitcast i8*%F to i32*
store i32 1342177304,i32*%G,align 4
store i8*%E,i8**%d,align 8
%H=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%I=bitcast i8*%E to i8**
store i8*%H,i8**%I,align 8
%J=getelementptr inbounds i8,i8*%E,i64 8
%K=bitcast i8*%J to void(...)**
store void(...)*bitcast(void(i8*,i32)*@_SMLLLN14UserErrorUtils20initializeErrorQueueE_46 to void(...)*),void(...)**%K,align 8
%L=getelementptr inbounds i8,i8*%E,i64 16
%M=bitcast i8*%L to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils20initializeErrorQueueE_78 to void(...)*),void(...)**%M,align 8
%N=getelementptr inbounds i8,i8*%E,i64 24
%O=bitcast i8*%N to i32*
store i32 -2147483647,i32*%O,align 4
%P=call i8*@sml_alloc(i32 inreg 12)#0
%Q=getelementptr inbounds i8,i8*%P,i64 -4
%R=bitcast i8*%Q to i32*
store i32 1342177288,i32*%R,align 4
store i8*%P,i8**%c,align 8
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
store i8*%W,i8**%e,align 8
%Z=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aa=bitcast i8*%W to i8**
store i8*%Z,i8**%aa,align 8
%ab=getelementptr inbounds i8,i8*%W,i64 8
%ac=bitcast i8*%ab to void(...)**
store void(...)*bitcast(i8*(i8*,i32)*@_SMLLLN14UserErrorUtils20getErrorsAndWarningsE_47 to void(...)*),void(...)**%ac,align 8
%ad=getelementptr inbounds i8,i8*%W,i64 16
%ae=bitcast i8*%ad to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils20getErrorsAndWarningsE_79 to void(...)*),void(...)**%ae,align 8
%af=getelementptr inbounds i8,i8*%W,i64 24
%ag=bitcast i8*%af to i32*
store i32 -2147483647,i32*%ag,align 4
%ah=call i8*@sml_alloc(i32 inreg 12)#0
%ai=getelementptr inbounds i8,i8*%ah,i64 -4
%aj=bitcast i8*%ai to i32*
store i32 1342177288,i32*%aj,align 4
store i8*%ah,i8**%c,align 8
%ak=load i8*,i8**%b,align 8
%al=bitcast i8*%ah to i8**
store i8*%ak,i8**%al,align 8
%am=getelementptr inbounds i8,i8*%ah,i64 8
%an=bitcast i8*%am to i32*
store i32 1,i32*%an,align 4
%ao=call i8*@sml_alloc(i32 inreg 28)#0
%ap=getelementptr inbounds i8,i8*%ao,i64 -4
%aq=bitcast i8*%ap to i32*
store i32 1342177304,i32*%aq,align 4
store i8*%ao,i8**%f,align 8
%ar=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%as=bitcast i8*%ao to i8**
store i8*%ar,i8**%as,align 8
%at=getelementptr inbounds i8,i8*%ao,i64 8
%au=bitcast i8*%at to void(...)**
store void(...)*bitcast(i8*(i8*,i32)*@_SMLLLN14UserErrorUtils9getErrorsE_48 to void(...)*),void(...)**%au,align 8
%av=getelementptr inbounds i8,i8*%ao,i64 16
%aw=bitcast i8*%av to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils9getErrorsE_80 to void(...)*),void(...)**%aw,align 8
%ax=getelementptr inbounds i8,i8*%ao,i64 24
%ay=bitcast i8*%ax to i32*
store i32 -2147483647,i32*%ay,align 4
%az=call i8*@sml_alloc(i32 inreg 12)#0
%aA=getelementptr inbounds i8,i8*%az,i64 -4
%aB=bitcast i8*%aA to i32*
store i32 1342177288,i32*%aB,align 4
store i8*%az,i8**%c,align 8
%aC=load i8*,i8**%b,align 8
%aD=bitcast i8*%az to i8**
store i8*%aC,i8**%aD,align 8
%aE=getelementptr inbounds i8,i8*%az,i64 8
%aF=bitcast i8*%aE to i32*
store i32 1,i32*%aF,align 4
%aG=call i8*@sml_alloc(i32 inreg 28)#0
%aH=getelementptr inbounds i8,i8*%aG,i64 -4
%aI=bitcast i8*%aH to i32*
store i32 1342177304,i32*%aI,align 4
store i8*%aG,i8**%g,align 8
%aJ=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aK=bitcast i8*%aG to i8**
store i8*%aJ,i8**%aK,align 8
%aL=getelementptr inbounds i8,i8*%aG,i64 8
%aM=bitcast i8*%aL to void(...)**
store void(...)*bitcast(i32(i8*,i32)*@_SMLLLN14UserErrorUtils10isAnyErrorE_49 to void(...)*),void(...)**%aM,align 8
%aN=getelementptr inbounds i8,i8*%aG,i64 16
%aO=bitcast i8*%aN to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils10isAnyErrorE_81 to void(...)*),void(...)**%aO,align 8
%aP=getelementptr inbounds i8,i8*%aG,i64 24
%aQ=bitcast i8*%aP to i32*
store i32 -2147483647,i32*%aQ,align 4
%aR=call i8*@sml_alloc(i32 inreg 12)#0
%aS=getelementptr inbounds i8,i8*%aR,i64 -4
%aT=bitcast i8*%aS to i32*
store i32 1342177288,i32*%aT,align 4
store i8*%aR,i8**%c,align 8
%aU=load i8*,i8**%b,align 8
%aV=bitcast i8*%aR to i8**
store i8*%aU,i8**%aV,align 8
%aW=getelementptr inbounds i8,i8*%aR,i64 8
%aX=bitcast i8*%aW to i32*
store i32 1,i32*%aX,align 4
%aY=call i8*@sml_alloc(i32 inreg 28)#0
%aZ=getelementptr inbounds i8,i8*%aY,i64 -4
%a0=bitcast i8*%aZ to i32*
store i32 1342177304,i32*%a0,align 4
store i8*%aY,i8**%h,align 8
%a1=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%a2=bitcast i8*%aY to i8**
store i8*%a1,i8**%a2,align 8
%a3=getelementptr inbounds i8,i8*%aY,i64 8
%a4=bitcast i8*%a3 to void(...)**
store void(...)*bitcast(i8*(i8*,i32)*@_SMLLLN14UserErrorUtils11getWarningsE_50 to void(...)*),void(...)**%a4,align 8
%a5=getelementptr inbounds i8,i8*%aY,i64 16
%a6=bitcast i8*%a5 to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils11getWarningsE_82 to void(...)*),void(...)**%a6,align 8
%a7=getelementptr inbounds i8,i8*%aY,i64 24
%a8=bitcast i8*%a7 to i32*
store i32 -2147483647,i32*%a8,align 4
%a9=load i8*,i8**%b,align 8
%ba=invoke fastcc i8*@_SMLFN9UserError12enqueueErrorE(i8*inreg%a9)
to label%bb unwind label%cy
bb:
store i8*%ba,i8**%c,align 8
%bc=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%bd=invoke fastcc i8*@_SMLFN9UserError14enqueueWarningE(i8*inreg%bc)
to label%be unwind label%cy
be:
store i8*%bd,i8**%b,align 8
%bf=call i8*@sml_alloc(i32 inreg 12)#0
%bg=getelementptr inbounds i8,i8*%bf,i64 -4
%bh=bitcast i8*%bg to i32*
store i32 1342177288,i32*%bh,align 4
store i8*%bf,i8**%i,align 8
%bi=load i8*,i8**%c,align 8
%bj=bitcast i8*%bf to i8**
store i8*%bi,i8**%bj,align 8
%bk=getelementptr inbounds i8,i8*%bf,i64 8
%bl=bitcast i8*%bk to i32*
store i32 1,i32*%bl,align 4
%bm=call i8*@sml_alloc(i32 inreg 28)#0
%bn=getelementptr inbounds i8,i8*%bm,i64 -4
%bo=bitcast i8*%bn to i32*
store i32 1342177304,i32*%bo,align 4
%bp=load i8*,i8**%i,align 8
%bq=bitcast i8*%bm to i8**
store i8*%bp,i8**%bq,align 8
%br=getelementptr inbounds i8,i8*%bm,i64 8
%bs=bitcast i8*%br to void(...)**
store void(...)*bitcast(void(i8*,i32,i32,i8*,i8*,i8*)*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_52 to void(...)*),void(...)**%bs,align 8
%bt=getelementptr inbounds i8,i8*%bm,i64 16
%bu=bitcast i8*%bt to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*,i8*,i8*,i8*)*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_84 to void(...)*),void(...)**%bu,align 8
%bv=getelementptr inbounds i8,i8*%bm,i64 24
%bw=bitcast i8*%bv to i32*
store i32 -2147483647,i32*%bw,align 4
%bx=call i8*@sml_alloc(i32 inreg 12)#0
%by=getelementptr inbounds i8,i8*%bx,i64 -4
%bz=bitcast i8*%by to i32*
store i32 1342177288,i32*%bz,align 4
store i8*%bx,i8**%j,align 8
%bA=load i8*,i8**%i,align 8
%bB=bitcast i8*%bx to i8**
store i8*%bA,i8**%bB,align 8
%bC=getelementptr inbounds i8,i8*%bx,i64 8
%bD=bitcast i8*%bC to i32*
store i32 1,i32*%bD,align 4
%bE=call i8*@sml_alloc(i32 inreg 28)#0
%bF=getelementptr inbounds i8,i8*%bE,i64 -4
%bG=bitcast i8*%bF to i32*
store i32 1342177304,i32*%bG,align 4
store i8*%bE,i8**%k,align 8
%bH=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%bI=bitcast i8*%bE to i8**
store i8*%bH,i8**%bI,align 8
%bJ=getelementptr inbounds i8,i8*%bE,i64 8
%bK=bitcast i8*%bJ to void(...)**
store void(...)*bitcast(i8*(i8*,i32,i32)*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_56 to void(...)*),void(...)**%bK,align 8
%bL=getelementptr inbounds i8,i8*%bE,i64 16
%bM=bitcast i8*%bL to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_86 to void(...)*),void(...)**%bM,align 8
%bN=getelementptr inbounds i8,i8*%bE,i64 24
%bO=bitcast i8*%bN to i32*
store i32 -2147483647,i32*%bO,align 4
%bP=call i8*@sml_alloc(i32 inreg 12)#0
%bQ=getelementptr inbounds i8,i8*%bP,i64 -4
%bR=bitcast i8*%bQ to i32*
store i32 1342177288,i32*%bR,align 4
store i8*%bP,i8**%j,align 8
%bS=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%bT=bitcast i8*%bP to i8**
store i8*%bS,i8**%bT,align 8
%bU=getelementptr inbounds i8,i8*%bP,i64 8
%bV=bitcast i8*%bU to i32*
store i32 1,i32*%bV,align 4
%bW=call i8*@sml_alloc(i32 inreg 28)#0
%bX=getelementptr inbounds i8,i8*%bW,i64 -4
%bY=bitcast i8*%bX to i32*
store i32 1342177304,i32*%bY,align 4
store i8*%bW,i8**%i,align 8
%bZ=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%b0=bitcast i8*%bW to i8**
store i8*%bZ,i8**%b0,align 8
%b1=getelementptr inbounds i8,i8*%bW,i64 8
%b2=bitcast i8*%b1 to void(...)**
store void(...)*bitcast(i8*(i8*,i32,i32)*@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_61 to void(...)*),void(...)**%b2,align 8
%b3=getelementptr inbounds i8,i8*%bW,i64 16
%b4=bitcast i8*%b3 to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_88 to void(...)*),void(...)**%b4,align 8
%b5=getelementptr inbounds i8,i8*%bW,i64 24
%b6=bitcast i8*%b5 to i32*
store i32 -2147483647,i32*%b6,align 4
%b7=call i8*@sml_alloc(i32 inreg 12)#0
%b8=getelementptr inbounds i8,i8*%b7,i64 -4
%b9=bitcast i8*%b8 to i32*
store i32 1342177288,i32*%b9,align 4
store i8*%b7,i8**%j,align 8
%ca=load i8*,i8**%c,align 8
%cb=bitcast i8*%b7 to i8**
store i8*%ca,i8**%cb,align 8
%cc=getelementptr inbounds i8,i8*%b7,i64 8
%cd=bitcast i8*%cc to i32*
store i32 1,i32*%cd,align 4
%ce=call i8*@sml_alloc(i32 inreg 28)#0
%cf=getelementptr inbounds i8,i8*%ce,i64 -4
%cg=bitcast i8*%cf to i32*
store i32 1342177304,i32*%cg,align 4
%ch=load i8*,i8**%j,align 8
%ci=bitcast i8*%ce to i8**
store i8*%ch,i8**%ci,align 8
%cj=getelementptr inbounds i8,i8*%ce,i64 8
%ck=bitcast i8*%cj to void(...)**
store void(...)*bitcast(i8*(i8*,i32,i32)*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_67 to void(...)*),void(...)**%ck,align 8
%cl=getelementptr inbounds i8,i8*%ce,i64 16
%cm=bitcast i8*%cl to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_91 to void(...)*),void(...)**%cm,align 8
%cn=getelementptr inbounds i8,i8*%ce,i64 24
%co=bitcast i8*%cn to i32*
store i32 -2147483647,i32*%co,align 4
%cp=load i8*,i8**%d,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 0),i8*inreg%cp)#0
%cq=load i8*,i8**%e,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 1),i8*inreg%cq)#0
%cr=load i8*,i8**%f,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 2),i8*inreg%cr)#0
%cs=load i8*,i8**%g,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 3),i8*inreg%cs)#0
%ct=load i8*,i8**%h,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 4),i8*inreg%ct)#0
%cu=load i8*,i8**%c,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 5),i8*inreg%cu)#0
%cv=load i8*,i8**%b,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 6),i8*inreg%cv)#0
%cw=load i8*,i8**%k,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 7),i8*inreg%cw)#0
%cx=load i8*,i8**%i,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 8),i8*inreg%cx)#0
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 9),i8*inreg%ce)#0
call void@sml_end()#0
ret void
cy:
%cz=landingpad{i8*,i8*}
cleanup
%cA=extractvalue{i8*,i8*}%cz,1
call void@sml_save_exn(i8*inreg%cA)#0
call void@sml_end()#0
resume{i8*,i8*}%cz
}
define internal fastcc void@_SMLLLN14UserErrorUtils20initializeErrorQueueE_46(i8*inreg%a,i32 inreg%b)#1 gc"smlsharp"{
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
define internal fastcc i8*@_SMLLLN14UserErrorUtils20getErrorsAndWarningsE_47(i8*inreg%a,i32 inreg%b)#1 gc"smlsharp"{
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
define internal fastcc i8*@_SMLLLN14UserErrorUtils9getErrorsE_48(i8*inreg%a,i32 inreg%b)#1 gc"smlsharp"{
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
define internal fastcc i32@_SMLLLN14UserErrorUtils10isAnyErrorE_49(i8*inreg%a,i32 inreg%b)#1 gc"smlsharp"{
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
define internal fastcc i8*@_SMLLLN14UserErrorUtils11getWarningsE_50(i8*inreg%a,i32 inreg%b)#1 gc"smlsharp"{
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
define internal fastcc void@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_51(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
br i1%h,label%i,label%k
i:
%j=bitcast i8*%a to i8**
br label%o
k:
call void@sml_check(i32 inreg%g)
%l=bitcast i8**%d to i8***
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
store i8*%x,i8**%e,align 8
%y=load i8*,i8**%d,align 8
%z=getelementptr inbounds i8,i8*%y,i64 8
%A=bitcast i8*%z to i8**
%B=load i8*,i8**%A,align 8
%C=getelementptr inbounds i8,i8*%B,i64 16
%D=bitcast i8*%C to i8*(i8*,i8*)**
%E=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%D,align 8
store i8*null,i8**%d,align 8
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
%M=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
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
define internal fastcc void@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_52(i8*inreg%a,i32 inreg%b,i32 inreg%c,i8*inreg%d,i8*inreg%e,i8*inreg%f)#1 gc"smlsharp"{
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
%k=alloca i8*,align 8
%l=alloca i8*,align 8
%m=alloca i8*,align 8
%n=alloca i8*,align 8
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
call void@llvm.gcroot(i8**%k,i8*null)#0
call void@llvm.gcroot(i8**%l,i8*null)#0
call void@llvm.gcroot(i8**%m,i8*null)#0
call void@llvm.gcroot(i8**%n,i8*null)#0
store i8*%a,i8**%m,align 8
store i8*%f,i8**%i,align 8
store i8*%e,i8**%h,align 8
store i8*%d,i8**%g,align 8
%o=add i32%c,-1
%p=sub i32 0,%c
%q=and i32%o,%p
%r=add i32%c,7
%s=add i32%r,%q
%t=and i32%s,-8
%u=call fastcc i8*@_SMLFN9SymbolEnv5emptyE(i32 inreg 1,i32 inreg 8)
store i8*%u,i8**%j,align 8
%v=call fastcc i8*@_SMLFN9SymbolEnv5emptyE(i32 inreg 1,i32 inreg 8)
%w=load i8*,i8**%h,align 8
%x=load i8*,i8**%j,align 8
store i8*%x,i8**%h,align 8
store i8*%v,i8**%j,align 8
store i8*%w,i8**%k,align 8
%y=icmp eq i32%b,0
%z=sext i32%q to i64
%A=sext i32%t to i64
br label%B
B:
%C=load atomic i32,i32*@sml_check_flag unordered,align 4
%D=icmp eq i32%C,0
br i1%D,label%F,label%E
E:
call void@sml_check(i32 inreg%C)
br label%F
F:
%G=load i8*,i8**%k,align 8
%H=icmp eq i8*%G,null
br i1%H,label%I,label%aE
I:
store i8*null,i8**%g,align 8
store i8*null,i8**%h,align 8
store i8*null,i8**%k,align 8
%J=call fastcc i8*@_SMLFN9SymbolEnv9listItemsE(i32 inreg 1,i32 inreg 8)
%K=getelementptr inbounds i8,i8*%J,i64 16
%L=bitcast i8*%K to i8*(i8*,i8*)**
%M=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%L,align 8
%N=bitcast i8*%J to i8**
%O=load i8*,i8**%N,align 8
%P=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%Q=call fastcc i8*%M(i8*inreg%O,i8*inreg%P)
store i8*%Q,i8**%g,align 8
%R=call fastcc i8*@_SMLFN4List3appE(i32 inreg 1,i32 inreg 8)
%S=getelementptr inbounds i8,i8*%R,i64 16
%T=bitcast i8*%S to i8*(i8*,i8*)**
%U=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%T,align 8
%V=bitcast i8*%R to i8**
%W=load i8*,i8**%V,align 8
store i8*%W,i8**%j,align 8
%X=bitcast i8**%m to i8***
%Y=load i8**,i8***%X,align 8
store i8*null,i8**%m,align 8
%Z=load i8*,i8**%Y,align 8
store i8*%Z,i8**%h,align 8
%aa=call i8*@sml_alloc(i32 inreg 20)#0
%ab=getelementptr inbounds i8,i8*%aa,i64 -4
%ac=bitcast i8*%ab to i32*
store i32 1342177296,i32*%ac,align 4
store i8*%aa,i8**%k,align 8
%ad=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%ae=bitcast i8*%aa to i8**
store i8*%ad,i8**%ae,align 8
%af=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%ag=getelementptr inbounds i8,i8*%aa,i64 8
%ah=bitcast i8*%ag to i8**
store i8*%af,i8**%ah,align 8
%ai=getelementptr inbounds i8,i8*%aa,i64 16
%aj=bitcast i8*%ai to i32*
store i32 3,i32*%aj,align 4
%ak=call i8*@sml_alloc(i32 inreg 28)#0
%al=getelementptr inbounds i8,i8*%ak,i64 -4
%am=bitcast i8*%al to i32*
store i32 1342177304,i32*%am,align 4
%an=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
%ao=bitcast i8*%ak to i8**
store i8*%an,i8**%ao,align 8
%ap=getelementptr inbounds i8,i8*%ak,i64 8
%aq=bitcast i8*%ap to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_51 to void(...)*),void(...)**%aq,align 8
%ar=getelementptr inbounds i8,i8*%ak,i64 16
%as=bitcast i8*%ar to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_83 to void(...)*),void(...)**%as,align 8
%at=getelementptr inbounds i8,i8*%ak,i64 24
%au=bitcast i8*%at to i32*
store i32 -2147483647,i32*%au,align 4
%av=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%aw=call fastcc i8*%U(i8*inreg%av,i8*inreg%ak)
%ax=getelementptr inbounds i8,i8*%aw,i64 16
%ay=bitcast i8*%ax to i8*(i8*,i8*)**
%az=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ay,align 8
%aA=bitcast i8*%aw to i8**
%aB=load i8*,i8**%aA,align 8
%aC=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aD=call fastcc i8*%az(i8*inreg%aB,i8*inreg%aC)
ret void
aE:
br i1%y,label%aJ,label%aF
aF:
%aG=getelementptr inbounds i8,i8*%G,i64%z
%aH=bitcast i8*%aG to i8**
%aI=load i8*,i8**%aH,align 8
br label%aP
aJ:
%aK=call i8*@sml_alloc(i32 inreg%c)#0
%aL=getelementptr inbounds i8,i8*%aK,i64 -4
%aM=bitcast i8*%aL to i32*
store i32%c,i32*%aM,align 4
%aN=load i8*,i8**%k,align 8
%aO=getelementptr inbounds i8,i8*%aN,i64%z
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aK,i8*%aO,i32%c,i1 false)
br label%aP
aP:
%aQ=phi i8*[%G,%aF],[%aN,%aJ]
%aR=phi i8*[%aI,%aF],[%aK,%aJ]
%aS=getelementptr inbounds i8,i8*%aQ,i64%A
%aT=bitcast i8*%aS to i8**
%aU=load i8*,i8**%aT,align 8
store i8*%aU,i8**%k,align 8
%aV=load i8*,i8**%g,align 8
%aW=getelementptr inbounds i8,i8*%aV,i64 16
%aX=bitcast i8*%aW to i8*(i8*,i8*)**
%aY=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aX,align 8
%aZ=bitcast i8*%aV to i8**
%a0=load i8*,i8**%aZ,align 8
%a1=call fastcc i8*%aY(i8*inreg%a0,i8*inreg%aR)
%a2=icmp eq i8*%a1,null
br i1%a2,label%b7,label%a3
a3:
%a4=bitcast i8*%a1 to i8**
%a5=load i8*,i8**%a4,align 8
store i8*%a5,i8**%l,align 8
%a6=call fastcc i8*@_SMLFN9SymbolEnv4findE(i32 inreg 1,i32 inreg 8)
%a7=getelementptr inbounds i8,i8*%a6,i64 16
%a8=bitcast i8*%a7 to i8*(i8*,i8*)**
%a9=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%a8,align 8
%ba=bitcast i8*%a6 to i8**
%bb=load i8*,i8**%ba,align 8
store i8*%bb,i8**%n,align 8
%bc=call i8*@sml_alloc(i32 inreg 20)#0
%bd=getelementptr inbounds i8,i8*%bc,i64 -4
%be=bitcast i8*%bd to i32*
store i32 1342177296,i32*%be,align 4
%bf=load i8*,i8**%h,align 8
%bg=bitcast i8*%bc to i8**
store i8*%bf,i8**%bg,align 8
%bh=load i8*,i8**%l,align 8
%bi=getelementptr inbounds i8,i8*%bc,i64 8
%bj=bitcast i8*%bi to i8**
store i8*%bh,i8**%bj,align 8
%bk=getelementptr inbounds i8,i8*%bc,i64 16
%bl=bitcast i8*%bk to i32*
store i32 3,i32*%bl,align 4
%bm=load i8*,i8**%n,align 8
store i8*null,i8**%n,align 8
%bn=call fastcc i8*%a9(i8*inreg%bm,i8*inreg%bc)
%bo=icmp eq i8*%bn,null
br i1%bo,label%bK,label%bp
bp:
%bq=call fastcc i8*@_SMLFN9SymbolEnv6insertE(i32 inreg 1,i32 inreg 8)
%br=getelementptr inbounds i8,i8*%bq,i64 16
%bs=bitcast i8*%br to i8*(i8*,i8*)**
%bt=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bs,align 8
%bu=bitcast i8*%bq to i8**
%bv=load i8*,i8**%bu,align 8
store i8*%bv,i8**%n,align 8
%bw=call i8*@sml_alloc(i32 inreg 28)#0
%bx=getelementptr inbounds i8,i8*%bw,i64 -4
%by=bitcast i8*%bx to i32*
store i32 1342177304,i32*%by,align 4
%bz=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%bA=bitcast i8*%bw to i8**
store i8*%bz,i8**%bA,align 8
%bB=load i8*,i8**%l,align 8
%bC=getelementptr inbounds i8,i8*%bw,i64 8
%bD=bitcast i8*%bC to i8**
store i8*%bB,i8**%bD,align 8
%bE=getelementptr inbounds i8,i8*%bw,i64 16
%bF=bitcast i8*%bE to i8**
store i8*%bB,i8**%bF,align 8
%bG=getelementptr inbounds i8,i8*%bw,i64 24
%bH=bitcast i8*%bG to i32*
store i32 7,i32*%bH,align 4
%bI=load i8*,i8**%n,align 8
store i8*null,i8**%n,align 8
%bJ=call fastcc i8*%bt(i8*inreg%bI,i8*inreg%bw)
store i8*%bJ,i8**%j,align 8
br label%bK
bK:
%bL=call fastcc i8*@_SMLFN9SymbolEnv6insertE(i32 inreg 1,i32 inreg 8)
%bM=getelementptr inbounds i8,i8*%bL,i64 16
%bN=bitcast i8*%bM to i8*(i8*,i8*)**
%bO=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bN,align 8
%bP=bitcast i8*%bL to i8**
%bQ=load i8*,i8**%bP,align 8
store i8*%bQ,i8**%n,align 8
%bR=call i8*@sml_alloc(i32 inreg 28)#0
%bS=getelementptr inbounds i8,i8*%bR,i64 -4
%bT=bitcast i8*%bS to i32*
store i32 1342177304,i32*%bT,align 4
%bU=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%bV=bitcast i8*%bR to i8**
store i8*%bU,i8**%bV,align 8
%bW=load i8*,i8**%l,align 8
%bX=getelementptr inbounds i8,i8*%bR,i64 8
%bY=bitcast i8*%bX to i8**
store i8*%bW,i8**%bY,align 8
store i8*null,i8**%l,align 8
%bZ=getelementptr inbounds i8,i8*%bR,i64 16
%b0=bitcast i8*%bZ to i8**
store i8*%bW,i8**%b0,align 8
%b1=getelementptr inbounds i8,i8*%bR,i64 24
%b2=bitcast i8*%b1 to i32*
store i32 7,i32*%b2,align 4
%b3=load i8*,i8**%n,align 8
store i8*null,i8**%n,align 8
%b4=call fastcc i8*%bO(i8*inreg%b3,i8*inreg%bR)
%b5=load i8*,i8**%k,align 8
%b6=load i8*,i8**%j,align 8
store i8*%b4,i8**%h,align 8
store i8*%b6,i8**%j,align 8
store i8*%b5,i8**%k,align 8
br label%b7
b7:
br label%B
}
define internal fastcc void@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_53(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
l:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%c,align 8
store i8*%b,i8**%d,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%j,label%g
g:
call void@sml_check(i32 inreg%e)
%h=load i8*,i8**%d,align 8
%i=load i8*,i8**%c,align 8
br label%j
j:
%k=phi i8*[%i,%g],[%a,%l]
%m=phi i8*[%h,%g],[%b,%l]
%n=getelementptr inbounds i8,i8*%k,i64 16
%o=bitcast i8*%n to i8**
%p=load i8*,i8**%o,align 8
%q=getelementptr inbounds i8,i8*%k,i64 24
%r=bitcast i8*%q to i32*
%s=load i32,i32*%r,align 4
%t=getelementptr inbounds i8,i8*%k,i64 28
%u=bitcast i8*%t to i32*
%v=load i32,i32*%u,align 4
%w=bitcast i8*%k to i8**
%x=load i8*,i8**%w,align 8
%y=getelementptr inbounds i8,i8*%k,i64 8
%z=bitcast i8*%y to i8**
%A=load i8*,i8**%z,align 8
call fastcc void@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_52(i8*inreg%p,i32 inreg%s,i32 inreg%v,i8*inreg%x,i8*inreg%A,i8*inreg%m)
ret void
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_54(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(void(i8*,i8*)*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_53 to void(...)*),void(...)**%O,align 8
%P=getelementptr inbounds i8,i8*%I,i64 16
%Q=bitcast i8*%P to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_85 to void(...)*),void(...)**%Q,align 8
%R=getelementptr inbounds i8,i8*%I,i64 24
%S=bitcast i8*%R to i32*
store i32 -2147483647,i32*%S,align 4
ret i8*%I
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_55(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_54 to void(...)*),void(...)**%H,align 8
%I=getelementptr inbounds i8,i8*%B,i64 16
%J=bitcast i8*%I to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_54 to void(...)*),void(...)**%J,align 8
%K=getelementptr inbounds i8,i8*%B,i64 24
%L=bitcast i8*%K to i32*
store i32 -2147483647,i32*%L,align 4
ret i8*%B
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_56(i8*inreg%a,i32 inreg%b,i32 inreg%c)#3 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_55 to void(...)*),void(...)**%y,align 8
%z=getelementptr inbounds i8,i8*%s,i64 16
%A=bitcast i8*%z to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_55 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%s,i64 24
%C=bitcast i8*%B to i32*
store i32 -2147483647,i32*%C,align 4
ret i8*%s
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_57(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%c,align 8
store i8*%b,i8**%d,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%g,label%i
g:
%h=bitcast i8*%a to i8**
br label%m
i:
call void@sml_check(i32 inreg%e)
%j=bitcast i8**%c to i8***
%k=load i8**,i8***%j,align 8
%l=load i8*,i8**%d,align 8
br label%m
m:
%n=phi i8*[%l,%i],[%b,%g]
%o=phi i8**[%k,%i],[%h,%g]
%p=load i8*,i8**%o,align 8
%q=getelementptr inbounds i8,i8*%p,i64 16
%r=bitcast i8*%q to i8*(i8*,i8*)**
%s=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%r,align 8
store i8*null,i8**%c,align 8
%t=bitcast i8**%o to i8***
%u=load i8**,i8***%t,align 8
%v=load i8*,i8**%u,align 8
store i8*null,i8**%d,align 8
%w=call fastcc i8*%s(i8*inreg%v,i8*inreg%n)
store i8*%w,i8**%c,align 8
%x=call i8*@sml_alloc(i32 inreg 12)#0
%y=getelementptr inbounds i8,i8*%x,i64 -4
%z=bitcast i8*%y to i32*
store i32 1342177288,i32*%z,align 4
%A=load i8*,i8**%c,align 8
%B=bitcast i8*%x to i8**
store i8*%A,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%x,i64 8
%D=bitcast i8*%C to i32*
store i32 1,i32*%D,align 4
ret i8*%x
}
define internal fastcc void@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_58(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
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
store i8*%q,i8**%f,align 8
%r=getelementptr inbounds i8,i8*%m,i64 24
%s=bitcast i8*%r to i32*
%t=load i32,i32*%s,align 4
%u=getelementptr inbounds i8,i8*%m,i64 28
%v=bitcast i8*%u to i32*
%w=load i32,i32*%v,align 4
%x=bitcast i8*%m to i8**
%y=load i8*,i8**%x,align 8
store i8*%y,i8**%e,align 8
%z=call i8*@sml_alloc(i32 inreg 12)#0
%A=getelementptr inbounds i8,i8*%z,i64 -4
%B=bitcast i8*%A to i32*
store i32 1342177288,i32*%B,align 4
store i8*%z,i8**%g,align 8
%C=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%D=bitcast i8*%z to i8**
store i8*%C,i8**%D,align 8
%E=getelementptr inbounds i8,i8*%z,i64 8
%F=bitcast i8*%E to i32*
store i32 1,i32*%F,align 4
%G=call i8*@sml_alloc(i32 inreg 28)#0
%H=getelementptr inbounds i8,i8*%G,i64 -4
%I=bitcast i8*%H to i32*
store i32 1342177304,i32*%I,align 4
%J=load i8*,i8**%g,align 8
%K=bitcast i8*%G to i8**
store i8*%J,i8**%K,align 8
%L=getelementptr inbounds i8,i8*%G,i64 8
%M=bitcast i8*%L to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_57 to void(...)*),void(...)**%M,align 8
%N=getelementptr inbounds i8,i8*%G,i64 16
%O=bitcast i8*%N to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_57 to void(...)*),void(...)**%O,align 8
%P=getelementptr inbounds i8,i8*%G,i64 24
%Q=bitcast i8*%P to i32*
store i32 1,i32*%Q,align 4
%R=load i8*,i8**%d,align 8
%S=getelementptr inbounds i8,i8*%R,i64 8
%T=bitcast i8*%S to i8**
%U=load i8*,i8**%T,align 8
%V=load i8*,i8**%c,align 8
%W=load i8*,i8**%f,align 8
call fastcc void@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_52(i8*inreg%W,i32 inreg%t,i32 inreg%w,i8*inreg%G,i8*inreg%U,i8*inreg%V)
ret void
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_59(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(void(i8*,i8*)*@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_58 to void(...)*),void(...)**%O,align 8
%P=getelementptr inbounds i8,i8*%I,i64 16
%Q=bitcast i8*%P to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_87 to void(...)*),void(...)**%Q,align 8
%R=getelementptr inbounds i8,i8*%I,i64 24
%S=bitcast i8*%R to i32*
store i32 -2147483647,i32*%S,align 4
ret i8*%I
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_60(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_59 to void(...)*),void(...)**%H,align 8
%I=getelementptr inbounds i8,i8*%B,i64 16
%J=bitcast i8*%I to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_59 to void(...)*),void(...)**%J,align 8
%K=getelementptr inbounds i8,i8*%B,i64 24
%L=bitcast i8*%K to i32*
store i32 -2147483647,i32*%L,align 4
ret i8*%B
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_61(i8*inreg%a,i32 inreg%b,i32 inreg%c)#3 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_60 to void(...)*),void(...)**%y,align 8
%z=getelementptr inbounds i8,i8*%s,i64 16
%A=bitcast i8*%z to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_60 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%s,i64 24
%C=bitcast i8*%B to i32*
store i32 -2147483647,i32*%C,align 4
ret i8*%s
}
define internal fastcc void@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_62(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%a,i8**%c,align 8
store i8*%b,i8**%d,align 8
%f=load atomic i32,i32*@sml_check_flag unordered,align 4
%g=icmp eq i32%f,0
br i1%g,label%h,label%j
h:
%i=bitcast i8*%a to i8**
br label%o
j:
call void@sml_check(i32 inreg%f)
%k=load i8*,i8**%d,align 8
%l=bitcast i8**%c to i8***
%m=load i8**,i8***%l,align 8
%n=bitcast i8**%m to i8*
br label%o
o:
%p=phi i8*[%n,%j],[%a,%h]
%q=phi i8**[%m,%j],[%i,%h]
%r=phi i8*[%k,%j],[%b,%h]
%s=load i8*,i8**%q,align 8
%t=getelementptr inbounds i8,i8*%s,i64 16
%u=bitcast i8*%t to i8*(i8*,i8*)**
%v=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%u,align 8
%w=bitcast i8*%s to i8**
%x=load i8*,i8**%w,align 8
store i8*%x,i8**%e,align 8
%y=getelementptr inbounds i8,i8*%p,i64 8
%z=bitcast i8*%y to i8**
%A=load i8*,i8**%z,align 8
store i8*%A,i8**%d,align 8
%B=getelementptr inbounds i8,i8*%p,i64 16
%C=bitcast i8*%B to i8**
%D=load i8*,i8**%C,align 8
%E=getelementptr inbounds i8,i8*%D,i64 16
%F=bitcast i8*%E to i8*(i8*,i8*)**
%G=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%F,align 8
store i8*null,i8**%c,align 8
%H=bitcast i8*%D to i8**
%I=load i8*,i8**%H,align 8
%J=call fastcc i8*%G(i8*inreg%I,i8*inreg%r)
store i8*%J,i8**%c,align 8
%K=call i8*@sml_alloc(i32 inreg 20)#0
%L=getelementptr inbounds i8,i8*%K,i64 -4
%M=bitcast i8*%L to i32*
store i32 1342177296,i32*%M,align 4
%N=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%O=bitcast i8*%K to i8**
store i8*%N,i8**%O,align 8
%P=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%Q=getelementptr inbounds i8,i8*%K,i64 8
%R=bitcast i8*%Q to i8**
store i8*%P,i8**%R,align 8
%S=getelementptr inbounds i8,i8*%K,i64 16
%T=bitcast i8*%S to i32*
store i32 3,i32*%T,align 4
%U=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%V=call fastcc i8*%v(i8*inreg%U,i8*inreg%K)
ret void
}
define internal fastcc void@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_63(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
store i8*%a,i8**%h,align 8
store i8*%b,i8**%c,align 8
%j=getelementptr inbounds i8,i8*%a,i64 36
%k=bitcast i8*%j to i32*
%l=load i32,i32*%k,align 4
%m=add i32%l,-1
%n=sub i32 0,%l
%o=and i32%m,%n
%p=add i32%l,7
%q=add i32%p,%o
%r=and i32%q,-8
%s=call fastcc i8*@_SMLFN11RecordLabel3Map5emptyE(i32 inreg 1,i32 inreg 8)
store i8*%s,i8**%d,align 8
%t=call fastcc i8*@_SMLFN11RecordLabel3Map5emptyE(i32 inreg 1,i32 inreg 8)
%u=load i8*,i8**%h,align 8
%v=getelementptr inbounds i8,i8*%u,i64 16
%w=bitcast i8*%v to i8**
%x=load i8*,i8**%w,align 8
store i8*%t,i8**%e,align 8
store i8*%x,i8**%f,align 8
%y=sext i32%o to i64
%z=sext i32%r to i64
br label%A
A:
%B=load atomic i32,i32*@sml_check_flag unordered,align 4
%C=icmp eq i32%B,0
br i1%C,label%E,label%D
D:
call void@sml_check(i32 inreg%B)
br label%E
E:
%F=load i8*,i8**%f,align 8
%G=icmp eq i8*%F,null
br i1%G,label%H,label%aI
H:
store i8*null,i8**%d,align 8
store i8*null,i8**%f,align 8
%I=call fastcc i8*@_SMLFN11RecordLabel3Map9listItemsE(i32 inreg 1,i32 inreg 8)
%J=getelementptr inbounds i8,i8*%I,i64 16
%K=bitcast i8*%J to i8*(i8*,i8*)**
%L=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%K,align 8
%M=bitcast i8*%I to i8**
%N=load i8*,i8**%M,align 8
%O=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%P=call fastcc i8*%L(i8*inreg%N,i8*inreg%O)
store i8*%P,i8**%d,align 8
%Q=call fastcc i8*@_SMLFN4List3appE(i32 inreg 1,i32 inreg 8)
%R=getelementptr inbounds i8,i8*%Q,i64 16
%S=bitcast i8*%R to i8*(i8*,i8*)**
%T=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%S,align 8
%U=bitcast i8*%Q to i8**
%V=load i8*,i8**%U,align 8
store i8*%V,i8**%g,align 8
%W=bitcast i8**%h to i8***
%X=load i8**,i8***%W,align 8
%Y=load i8*,i8**%X,align 8
store i8*%Y,i8**%e,align 8
store i8*null,i8**%h,align 8
%Z=getelementptr inbounds i8*,i8**%X,i64 3
%aa=load i8*,i8**%Z,align 8
store i8*%aa,i8**%f,align 8
%ab=call i8*@sml_alloc(i32 inreg 28)#0
%ac=getelementptr inbounds i8,i8*%ab,i64 -4
%ad=bitcast i8*%ac to i32*
store i32 1342177304,i32*%ad,align 4
store i8*%ab,i8**%h,align 8
%ae=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%af=bitcast i8*%ab to i8**
store i8*%ae,i8**%af,align 8
%ag=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ah=getelementptr inbounds i8,i8*%ab,i64 8
%ai=bitcast i8*%ah to i8**
store i8*%ag,i8**%ai,align 8
%aj=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ak=getelementptr inbounds i8,i8*%ab,i64 16
%al=bitcast i8*%ak to i8**
store i8*%aj,i8**%al,align 8
%am=getelementptr inbounds i8,i8*%ab,i64 24
%an=bitcast i8*%am to i32*
store i32 7,i32*%an,align 4
%ao=call i8*@sml_alloc(i32 inreg 28)#0
%ap=getelementptr inbounds i8,i8*%ao,i64 -4
%aq=bitcast i8*%ap to i32*
store i32 1342177304,i32*%aq,align 4
%ar=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%as=bitcast i8*%ao to i8**
store i8*%ar,i8**%as,align 8
%at=getelementptr inbounds i8,i8*%ao,i64 8
%au=bitcast i8*%at to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_62 to void(...)*),void(...)**%au,align 8
%av=getelementptr inbounds i8,i8*%ao,i64 16
%aw=bitcast i8*%av to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_89 to void(...)*),void(...)**%aw,align 8
%ax=getelementptr inbounds i8,i8*%ao,i64 24
%ay=bitcast i8*%ax to i32*
store i32 -2147483647,i32*%ay,align 4
%az=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aA=call fastcc i8*%T(i8*inreg%az,i8*inreg%ao)
%aB=getelementptr inbounds i8,i8*%aA,i64 16
%aC=bitcast i8*%aB to i8*(i8*,i8*)**
%aD=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aC,align 8
%aE=bitcast i8*%aA to i8**
%aF=load i8*,i8**%aE,align 8
%aG=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aH=call fastcc i8*%aD(i8*inreg%aF,i8*inreg%aG)
ret void
aI:
%aJ=load i8*,i8**%h,align 8
%aK=getelementptr inbounds i8,i8*%aJ,i64 32
%aL=bitcast i8*%aK to i32*
%aM=load i32,i32*%aL,align 4
%aN=icmp eq i32%aM,0
br i1%aN,label%aS,label%aO
aO:
%aP=getelementptr inbounds i8,i8*%F,i64%y
%aQ=bitcast i8*%aP to i8**
%aR=load i8*,i8**%aQ,align 8
br label%a2
aS:
%aT=getelementptr inbounds i8,i8*%aJ,i64 36
%aU=bitcast i8*%aT to i32*
%aV=load i32,i32*%aU,align 4
%aW=call i8*@sml_alloc(i32 inreg%aV)#0
%aX=getelementptr inbounds i8,i8*%aW,i64 -4
%aY=bitcast i8*%aX to i32*
store i32%aV,i32*%aY,align 4
%aZ=load i8*,i8**%f,align 8
%a0=getelementptr inbounds i8,i8*%aZ,i64%y
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%aW,i8*%a0,i32%aV,i1 false)
%a1=load i8*,i8**%h,align 8
br label%a2
a2:
%a3=phi i8*[%aJ,%aO],[%a1,%aS]
%a4=phi i8*[%F,%aO],[%aZ,%aS]
%a5=phi i8*[%aR,%aO],[%aW,%aS]
%a6=getelementptr inbounds i8,i8*%a4,i64%z
%a7=bitcast i8*%a6 to i8**
%a8=load i8*,i8**%a7,align 8
store i8*%a8,i8**%f,align 8
%a9=getelementptr inbounds i8,i8*%a3,i64 8
%ba=bitcast i8*%a9 to i8**
%bb=load i8*,i8**%ba,align 8
%bc=getelementptr inbounds i8,i8*%bb,i64 16
%bd=bitcast i8*%bc to i8*(i8*,i8*)**
%be=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bd,align 8
%bf=bitcast i8*%bb to i8**
%bg=load i8*,i8**%bf,align 8
%bh=call fastcc i8*%be(i8*inreg%bg,i8*inreg%a5)
store i8*%bh,i8**%g,align 8
%bi=call i8*@sml_alloc(i32 inreg 12)#0
%bj=getelementptr inbounds i8,i8*%bi,i64 -4
%bk=bitcast i8*%bj to i32*
store i32 1342177288,i32*%bk,align 4
%bl=load i8*,i8**%g,align 8
%bm=bitcast i8*%bi to i8**
store i8*%bl,i8**%bm,align 8
%bn=getelementptr inbounds i8,i8*%bi,i64 8
%bo=bitcast i8*%bn to i32*
store i32 1,i32*%bo,align 4
%bp=icmp eq i8*%bi,null
br i1%bp,label%bq,label%bs
bq:
store i8*null,i8**%g,align 8
br label%br
br:
br label%A
bs:
%bt=call fastcc i8*@_SMLFN11RecordLabel3Map4findE(i32 inreg 1,i32 inreg 8)
%bu=getelementptr inbounds i8,i8*%bt,i64 16
%bv=bitcast i8*%bu to i8*(i8*,i8*)**
%bw=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bv,align 8
%bx=bitcast i8*%bt to i8**
%by=load i8*,i8**%bx,align 8
store i8*%by,i8**%i,align 8
%bz=call i8*@sml_alloc(i32 inreg 20)#0
%bA=getelementptr inbounds i8,i8*%bz,i64 -4
%bB=bitcast i8*%bA to i32*
store i32 1342177296,i32*%bB,align 4
%bC=load i8*,i8**%d,align 8
%bD=bitcast i8*%bz to i8**
store i8*%bC,i8**%bD,align 8
%bE=load i8*,i8**%g,align 8
%bF=getelementptr inbounds i8,i8*%bz,i64 8
%bG=bitcast i8*%bF to i8**
store i8*%bE,i8**%bG,align 8
%bH=getelementptr inbounds i8,i8*%bz,i64 16
%bI=bitcast i8*%bH to i32*
store i32 3,i32*%bI,align 4
%bJ=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%bK=call fastcc i8*%bw(i8*inreg%bJ,i8*inreg%bz)
%bL=icmp eq i8*%bK,null
br i1%bL,label%b7,label%bM
bM:
%bN=call fastcc i8*@_SMLFN11RecordLabel3Map6insertE(i32 inreg 1,i32 inreg 8)
%bO=getelementptr inbounds i8,i8*%bN,i64 16
%bP=bitcast i8*%bO to i8*(i8*,i8*)**
%bQ=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bP,align 8
%bR=bitcast i8*%bN to i8**
%bS=load i8*,i8**%bR,align 8
store i8*%bS,i8**%i,align 8
%bT=call i8*@sml_alloc(i32 inreg 28)#0
%bU=getelementptr inbounds i8,i8*%bT,i64 -4
%bV=bitcast i8*%bU to i32*
store i32 1342177304,i32*%bV,align 4
%bW=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bX=bitcast i8*%bT to i8**
store i8*%bW,i8**%bX,align 8
%bY=load i8*,i8**%g,align 8
%bZ=getelementptr inbounds i8,i8*%bT,i64 8
%b0=bitcast i8*%bZ to i8**
store i8*%bY,i8**%b0,align 8
%b1=getelementptr inbounds i8,i8*%bT,i64 16
%b2=bitcast i8*%b1 to i8**
store i8*%bY,i8**%b2,align 8
%b3=getelementptr inbounds i8,i8*%bT,i64 24
%b4=bitcast i8*%b3 to i32*
store i32 7,i32*%b4,align 4
%b5=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%b6=call fastcc i8*%bQ(i8*inreg%b5,i8*inreg%bT)
store i8*%b6,i8**%e,align 8
br label%b7
b7:
%b8=call fastcc i8*@_SMLFN11RecordLabel3Map6insertE(i32 inreg 1,i32 inreg 8)
%b9=getelementptr inbounds i8,i8*%b8,i64 16
%ca=bitcast i8*%b9 to i8*(i8*,i8*)**
%cb=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ca,align 8
%cc=bitcast i8*%b8 to i8**
%cd=load i8*,i8**%cc,align 8
store i8*%cd,i8**%i,align 8
%ce=call i8*@sml_alloc(i32 inreg 28)#0
%cf=getelementptr inbounds i8,i8*%ce,i64 -4
%cg=bitcast i8*%cf to i32*
store i32 1342177304,i32*%cg,align 4
%ch=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ci=bitcast i8*%ce to i8**
store i8*%ch,i8**%ci,align 8
%cj=load i8*,i8**%g,align 8
%ck=getelementptr inbounds i8,i8*%ce,i64 8
%cl=bitcast i8*%ck to i8**
store i8*%cj,i8**%cl,align 8
store i8*null,i8**%g,align 8
%cm=getelementptr inbounds i8,i8*%ce,i64 16
%cn=bitcast i8*%cm to i8**
store i8*%cj,i8**%cn,align 8
%co=getelementptr inbounds i8,i8*%ce,i64 24
%cp=bitcast i8*%co to i32*
store i32 7,i32*%cp,align 4
%cq=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%cr=call fastcc i8*%cb(i8*inreg%cq,i8*inreg%ce)
%cs=load i8*,i8**%f,align 8
%ct=load i8*,i8**%e,align 8
store i8*%cr,i8**%d,align 8
store i8*%ct,i8**%e,align 8
store i8*%cs,i8**%f,align 8
br label%br
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_64(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(void(i8*,i8*)*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_63 to void(...)*),void(...)**%V,align 8
%W=getelementptr inbounds i8,i8*%P,i64 16
%X=bitcast i8*%W to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_90 to void(...)*),void(...)**%X,align 8
%Y=getelementptr inbounds i8,i8*%P,i64 24
%Z=bitcast i8*%Y to i32*
store i32 -2147483647,i32*%Z,align 4
ret i8*%P
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_65(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_64 to void(...)*),void(...)**%O,align 8
%P=getelementptr inbounds i8,i8*%I,i64 16
%Q=bitcast i8*%P to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_64 to void(...)*),void(...)**%Q,align 8
%R=getelementptr inbounds i8,i8*%I,i64 24
%S=bitcast i8*%R to i32*
store i32 -2147483647,i32*%S,align 4
ret i8*%I
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_66(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_65 to void(...)*),void(...)**%H,align 8
%I=getelementptr inbounds i8,i8*%B,i64 16
%J=bitcast i8*%I to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_65 to void(...)*),void(...)**%J,align 8
%K=getelementptr inbounds i8,i8*%B,i64 24
%L=bitcast i8*%K to i32*
store i32 -2147483647,i32*%L,align 4
ret i8*%B
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_67(i8*inreg%a,i32 inreg%b,i32 inreg%c)#3 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_66 to void(...)*),void(...)**%y,align 8
%z=getelementptr inbounds i8,i8*%s,i64 16
%A=bitcast i8*%z to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_66 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%s,i64 24
%C=bitcast i8*%B to i32*
store i32 -2147483647,i32*%C,align 4
ret i8*%s
}
define fastcc void@_SMLFN14UserErrorUtils20initializeErrorQueueE(i32 inreg%a)local_unnamed_addr#1 gc"smlsharp"{
%b=load atomic i32,i32*@sml_check_flag unordered,align 4
%c=icmp eq i32%b,0
br i1%c,label%e,label%d
d:
tail call void@sml_check(i32 inreg%b)
br label%e
e:
%f=load i8**,i8***bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 0)to i8***),align 8
%g=load i8*,i8**%f,align 8
tail call fastcc void@_SMLLLN14UserErrorUtils20initializeErrorQueueE_46(i8*inreg%g,i32 inreg%a)
ret void
}
define fastcc i8*@_SMLFN14UserErrorUtils20getErrorsAndWarningsE(i32 inreg%a)local_unnamed_addr#1 gc"smlsharp"{
%b=load atomic i32,i32*@sml_check_flag unordered,align 4
%c=icmp eq i32%b,0
br i1%c,label%e,label%d
d:
tail call void@sml_check(i32 inreg%b)
br label%e
e:
%f=load i8**,i8***bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 1)to i8***),align 8
%g=load i8*,i8**%f,align 8
%h=tail call fastcc i8*@_SMLLLN14UserErrorUtils20getErrorsAndWarningsE_47(i8*inreg%g,i32 inreg%a)
ret i8*%h
}
define fastcc i8*@_SMLFN14UserErrorUtils9getErrorsE(i32 inreg%a)local_unnamed_addr#1 gc"smlsharp"{
%b=load atomic i32,i32*@sml_check_flag unordered,align 4
%c=icmp eq i32%b,0
br i1%c,label%e,label%d
d:
tail call void@sml_check(i32 inreg%b)
br label%e
e:
%f=load i8**,i8***bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 2)to i8***),align 8
%g=load i8*,i8**%f,align 8
%h=tail call fastcc i8*@_SMLLLN14UserErrorUtils9getErrorsE_48(i8*inreg%g,i32 inreg%a)
ret i8*%h
}
define fastcc i32@_SMLFN14UserErrorUtils10isAnyErrorE(i32 inreg%a)local_unnamed_addr#1 gc"smlsharp"{
%b=load atomic i32,i32*@sml_check_flag unordered,align 4
%c=icmp eq i32%b,0
br i1%c,label%e,label%d
d:
tail call void@sml_check(i32 inreg%b)
br label%e
e:
%f=load i8**,i8***bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 3)to i8***),align 8
%g=load i8*,i8**%f,align 8
%h=tail call fastcc i32@_SMLLLN14UserErrorUtils10isAnyErrorE_49(i8*inreg%g,i32 inreg%a)
ret i32%h
}
define fastcc i8*@_SMLFN14UserErrorUtils11getWarningsE(i32 inreg%a)local_unnamed_addr#1 gc"smlsharp"{
%b=load atomic i32,i32*@sml_check_flag unordered,align 4
%c=icmp eq i32%b,0
br i1%c,label%e,label%d
d:
tail call void@sml_check(i32 inreg%b)
br label%e
e:
%f=load i8**,i8***bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 4)to i8***),align 8
%g=load i8*,i8**%f,align 8
%h=tail call fastcc i8*@_SMLLLN14UserErrorUtils11getWarningsE_50(i8*inreg%g,i32 inreg%a)
ret i8*%h
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
%j=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 5),align 8
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
%j=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 6),align 8
%k=getelementptr inbounds i8,i8*%j,i64 16
%l=bitcast i8*%k to i8*(i8*,i8*)**
%m=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%l,align 8
%n=bitcast i8*%j to i8**
%o=load i8*,i8**%n,align 8
%p=call fastcc i8*%m(i8*inreg%o,i8*inreg%h)
ret void
}
define fastcc i8*@_SMLFN14UserErrorUtils23checkSymbolDuplication_GE(i32 inreg%a,i32 inreg%b)local_unnamed_addr#1 gc"smlsharp"{
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
tail call void@sml_check(i32 inreg%c)
br label%f
f:
%g=load i8**,i8***bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 7)to i8***),align 8
%h=load i8*,i8**%g,align 8
%i=tail call fastcc i8*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_56(i8*inreg%h,i32 inreg%a,i32 inreg%b)
ret i8*%i
}
define fastcc i8*@_SMLFN14UserErrorUtils22checkSymbolDuplicationE(i32 inreg%a,i32 inreg%b)local_unnamed_addr#1 gc"smlsharp"{
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
tail call void@sml_check(i32 inreg%c)
br label%f
f:
%g=load i8**,i8***bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 8)to i8***),align 8
%h=load i8*,i8**%g,align 8
%i=tail call fastcc i8*@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_61(i8*inreg%h,i32 inreg%a,i32 inreg%b)
ret i8*%i
}
define fastcc i8*@_SMLFN14UserErrorUtils27checkRecordLabelDuplicationE(i32 inreg%a,i32 inreg%b)local_unnamed_addr#1 gc"smlsharp"{
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
tail call void@sml_check(i32 inreg%c)
br label%f
f:
%g=load i8**,i8***bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[10x i8*]}>,<{[4x i8],i32,[10x i8*]}>*@_SML_gvarc86a8a57f9dc856e_UserErrorUtils,i64 0,i32 2,i64 9)to i8***),align 8
%h=load i8*,i8**%g,align 8
%i=tail call fastcc i8*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_67(i8*inreg%h,i32 inreg%a,i32 inreg%b)
ret i8*%i
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils20initializeErrorQueueE_78(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
tail call fastcc void@_SMLLLN14UserErrorUtils20initializeErrorQueueE_46(i8*inreg%a,i32 inreg%d)
%e=tail call i8*@sml_alloc(i32 inreg 4)#0
%f=bitcast i8*%e to i32*
%g=getelementptr inbounds i8,i8*%e,i64 -4
%h=bitcast i8*%g to i32*
store i32 4,i32*%h,align 4
store i32 0,i32*%f,align 4
ret i8*%e
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils20getErrorsAndWarningsE_79(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=tail call fastcc i8*@_SMLLLN14UserErrorUtils20getErrorsAndWarningsE_47(i8*inreg%a,i32 inreg%d)
ret i8*%e
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils9getErrorsE_80(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=tail call fastcc i8*@_SMLLLN14UserErrorUtils9getErrorsE_48(i8*inreg%a,i32 inreg%d)
ret i8*%e
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils10isAnyErrorE_81(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=tail call fastcc i32@_SMLLLN14UserErrorUtils10isAnyErrorE_49(i8*inreg%a,i32 inreg%d)
%f=tail call i8*@sml_alloc(i32 inreg 4)#0
%g=bitcast i8*%f to i32*
%h=getelementptr inbounds i8,i8*%f,i64 -4
%i=bitcast i8*%h to i32*
store i32 4,i32*%i,align 4
store i32%e,i32*%g,align 4
ret i8*%f
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils11getWarningsE_82(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=tail call fastcc i8*@_SMLLLN14UserErrorUtils11getWarningsE_50(i8*inreg%a,i32 inreg%d)
ret i8*%e
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_83(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_51(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_84(i8*inreg%a,i8*inreg%b,i8*inreg%c,i8*inreg%d,i8*inreg%e,i8*inreg%f)#1 gc"smlsharp"{
%g=bitcast i8*%b to i32*
%h=load i32,i32*%g,align 4
%i=bitcast i8*%c to i32*
%j=load i32,i32*%i,align 4
tail call fastcc void@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_52(i8*inreg%a,i32 inreg%h,i32 inreg%j,i8*inreg%d,i8*inreg%e,i8*inreg%f)
%k=tail call i8*@sml_alloc(i32 inreg 4)#0
%l=bitcast i8*%k to i32*
%m=getelementptr inbounds i8,i8*%k,i64 -4
%n=bitcast i8*%m to i32*
store i32 4,i32*%n,align 4
store i32 0,i32*%l,align 4
ret i8*%k
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_85(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_53(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_86(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLLLN14UserErrorUtils23checkSymbolDuplication_GE_56(i8*inreg%a,i32 inreg%e,i32 inreg%g)
ret i8*%h
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_87(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_58(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_88(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLLLN14UserErrorUtils22checkSymbolDuplicationE_61(i8*inreg%a,i32 inreg%e,i32 inreg%g)
ret i8*%h
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_89(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_62(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_90(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_63(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_91(i8*inreg%a,i8*inreg%b,i8*inreg%c)#3 gc"smlsharp"{
%d=bitcast i8*%b to i32*
%e=load i32,i32*%d,align 4
%f=bitcast i8*%c to i32*
%g=load i32,i32*%f,align 4
%h=tail call fastcc i8*@_SMLLLN14UserErrorUtils27checkRecordLabelDuplicationE_67(i8*inreg%a,i32 inreg%e,i32 inreg%g)
ret i8*%h
}
declare void@llvm.memcpy.p0i8.p0i8.i32(i8*,i8*,i32,i1)#0
attributes#0={nounwind}
attributes#1={uwtable}
attributes#2={noreturn nounwind}
attributes#3={nounwind uwtable}
