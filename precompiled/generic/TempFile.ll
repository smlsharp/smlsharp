@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN16SMLSharp__Runtime6SysErrE=external local_unnamed_addr global i8*
@_SMLZN9CoreUtils7rmdir__fE=external local_unnamed_addr global i8*
@_SMLZ4Fail=external unnamed_addr constant i8*
@_SMLDL48=private global<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1342177272,i8*null}>,align 8
@_SMLDL49=private global<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1342177272,i8*null}>,align 8
@a=private unnamed_addr constant<{[4x i8],i32,[6x i8]}><{[4x i8]zeroinitializer,i32 -2147483642,[6x i8]c"exist\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,[57x i8]}><{[4x i8]zeroinitializer,i32 -2147483591,[57x i8]c"src/compiler/libs/toolchain/main/TempFile.sml:27.17(812)\00"}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,[36x i8]}><{[4x i8]zeroinitializer,i32 -2147483612,[36x i8]c"failed to make temporally directory\00"}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,[1x i8]}><{[4x i8]zeroinitializer,i32 -2147483647,[1x i8]zeroinitializer}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c".\00"}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN8TempFile6createE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8TempFile6createE_60 to void(...)*),i32 -2147483647}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(void(i32)*@_SMLFN8TempFile7cleanupE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8TempFile7cleanupE_61 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN8TempFile6createE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@f,i64 0,i32 2)to i8*)
@_SMLZN8TempFile7cleanupE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@g,i64 0,i32 2)to i8*)
@h=private unnamed_addr global[3x i64][i64 2,i64 sub(i64 ptrtoint(i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL48,i32 0,i32 0,i32 0),i32 8)to i64),i64 ptrtoint([3x i64]*@h to i64)),i64 sub(i64 ptrtoint(i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL49,i32 0,i32 0,i32 0),i32 8)to i64),i64 ptrtoint([3x i64]*@h to i64))]
@_SML_ftabca0e9aa4897964a8_TempFile=external global i8
@i=private unnamed_addr global i8 0
@j=internal unnamed_addr global i32 0,align 8
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i32@sml_obj_equal(i8*inreg,i8*inreg)local_unnamed_addr#0
declare i32@sml_personality(...)#0
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare void@sml_write(i8*inreg,i8**inreg,i8*inreg)local_unnamed_addr#0
declare i8*@_SMLFN16SMLSharp__Runtime9errorNameE(i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN18SMLSharp__OSFileSys7tmpNameE(i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN5Int323fmtE(i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN6Option3mapE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN6String1_ZE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN6String8isPrefixE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN8Filename10concatPathE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN8Filename10fromStringE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SMLFN9CoreUtils4rm__fE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SMLFN9CoreUtils5mkdirE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SMLFN9CoreUtils7newFileE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SMLFN9CoreUtils7rmdir__fE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN9StringCvt7padLeftE(i8 inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main5c37eb24573fc5f9_StringCvt()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main5148a836b3728be9_Int32()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_mainb802741546ad758e_SMLSharp_OSFileSys()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main00d884c96265bfea_SMLSharp_Runtime()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main3a60343781315c1e_Option()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main1ef93e13728790b1_String()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maine29d9c3af819282f_Filename()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_mainbda7a2fa42fa5d88_CoreUtils()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load5c37eb24573fc5f9_StringCvt(i8*)local_unnamed_addr
declare void@_SML_load5148a836b3728be9_Int32(i8*)local_unnamed_addr
declare void@_SML_loadb802741546ad758e_SMLSharp_OSFileSys(i8*)local_unnamed_addr
declare void@_SML_load00d884c96265bfea_SMLSharp_Runtime(i8*)local_unnamed_addr
declare void@_SML_load3a60343781315c1e_Option(i8*)local_unnamed_addr
declare void@_SML_load1ef93e13728790b1_String(i8*)local_unnamed_addr
declare void@_SML_loade29d9c3af819282f_Filename(i8*)local_unnamed_addr
declare void@_SML_loadbda7a2fa42fa5d88_CoreUtils(i8*)local_unnamed_addr
define private void@_SML_tabbca0e9aa4897964a8_TempFile()#3{
unreachable
}
define void@_SML_loadca0e9aa4897964a8_TempFile(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@i,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@i,align 1
tail call void@_SML_load5c37eb24573fc5f9_StringCvt(i8*%a)#0
tail call void@_SML_load5148a836b3728be9_Int32(i8*%a)#0
tail call void@_SML_loadb802741546ad758e_SMLSharp_OSFileSys(i8*%a)#0
tail call void@_SML_load00d884c96265bfea_SMLSharp_Runtime(i8*%a)#0
tail call void@_SML_load3a60343781315c1e_Option(i8*%a)#0
tail call void@_SML_load1ef93e13728790b1_String(i8*%a)#0
tail call void@_SML_loade29d9c3af819282f_Filename(i8*%a)#0
tail call void@_SML_loadbda7a2fa42fa5d88_CoreUtils(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbca0e9aa4897964a8_TempFile,i8*@_SML_ftabca0e9aa4897964a8_TempFile,i8*bitcast([3x i64]*@h to i8*))#0
ret void
}
define void@_SML_mainca0e9aa4897964a8_TempFile()local_unnamed_addr#2 gc"smlsharp"{
%a=load i8,i8*@i,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@i,align 1
tail call void@_SML_main5c37eb24573fc5f9_StringCvt()#2
tail call void@_SML_main5148a836b3728be9_Int32()#2
tail call void@_SML_mainb802741546ad758e_SMLSharp_OSFileSys()#2
tail call void@_SML_main00d884c96265bfea_SMLSharp_Runtime()#2
tail call void@_SML_main3a60343781315c1e_Option()#2
tail call void@_SML_main1ef93e13728790b1_String()#2
tail call void@_SML_maine29d9c3af819282f_Filename()#2
tail call void@_SML_mainbda7a2fa42fa5d88_CoreUtils()#2
br label%d
}
define fastcc i8*@_SMLFN8TempFile6createE(i8*inreg%a)#2 gc"smlsharp"personality i32(...)*@sml_personality{
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
br i1%g,label%i,label%h
h:
call void@sml_check(i32 inreg%f)
br label%i
i:
%j=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL48,i64 0,i32 2),align 8
%k=icmp eq i8*%j,null
br i1%k,label%l,label%aS
l:
%m=phi i32[%aB,%aA],[5,%i]
%n=icmp eq i32%m,0
br i1%n,label%o,label%I
o:
%p=load i8*,i8**@_SMLZ4Fail,align 8
store i8*%p,i8**%b,align 8
%q=call i8*@sml_alloc(i32 inreg 28)#0
%r=getelementptr inbounds i8,i8*%q,i64 -4
%s=bitcast i8*%r to i32*
store i32 1342177304,i32*%s,align 4
store i8*%q,i8**%c,align 8
%t=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%u=bitcast i8*%q to i8**
store i8*%t,i8**%u,align 8
%v=getelementptr inbounds i8,i8*%q,i64 8
%w=bitcast i8*%v to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[57x i8]}>,<{[4x i8],i32,[57x i8]}>*@b,i64 0,i32 2,i64 0),i8**%w,align 8
%x=getelementptr inbounds i8,i8*%q,i64 16
%y=bitcast i8*%x to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[36x i8]}>,<{[4x i8],i32,[36x i8]}>*@c,i64 0,i32 2,i64 0),i8**%y,align 8
%z=getelementptr inbounds i8,i8*%q,i64 24
%A=bitcast i8*%z to i32*
store i32 7,i32*%A,align 4
%B=call i8*@sml_alloc(i32 inreg 60)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177336,i32*%D,align 4
%E=getelementptr inbounds i8,i8*%B,i64 56
%F=bitcast i8*%E to i32*
store i32 1,i32*%F,align 4
%G=load i8*,i8**%c,align 8
%H=bitcast i8*%B to i8**
store i8*%G,i8**%H,align 8
call void@sml_raise(i8*inreg%B)#1
unreachable
I:
%J=call fastcc i8*@_SMLFN18SMLSharp__OSFileSys7tmpNameE(i32 inreg 0)
%K=call fastcc i8*@_SMLFN8Filename10fromStringE(i8*inreg%J)
store i8*%K,i8**%c,align 8
invoke fastcc void@_SMLFN9CoreUtils4rm__fE(i8*inreg%K)
to label%L unwind label%V
L:
%M=load i8*,i8**%c,align 8
invoke fastcc void@_SMLFN9CoreUtils5mkdirE(i8*inreg%M)
to label%N unwind label%V
N:
%O=call i8*@sml_alloc(i32 inreg 12)#0
%P=getelementptr inbounds i8,i8*%O,i64 -4
%Q=bitcast i8*%P to i32*
store i32 1342177288,i32*%Q,align 4
%R=load i8*,i8**%c,align 8
%S=bitcast i8*%O to i8**
store i8*%R,i8**%S,align 8
%T=getelementptr inbounds i8,i8*%O,i64 8
%U=bitcast i8*%T to i32*
store i32 1,i32*%U,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL48,i64 0,i32 2)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL48,i64 0,i32 2),i8*inreg%O)#0
br label%aV
V:
%W=landingpad{i8*,i8*}
catch i8*null
%X=extractvalue{i8*,i8*}%W,1
%Y=bitcast i8*%X to i8**
%Z=load i8*,i8**%Y,align 8
store i8*%Z,i8**%c,align 8
%aa=bitcast i8*%Z to i8**
%ab=load i8*,i8**%aa,align 8
%ac=load i8*,i8**@_SMLZN16SMLSharp__Runtime6SysErrE,align 8
%ad=icmp eq i8*%ab,%ac
br i1%ad,label%ae,label%aK
ae:
%af=getelementptr inbounds i8,i8*%Z,i64 16
%ag=bitcast i8*%af to i8**
%ah=load i8*,i8**%ag,align 8
%ai=getelementptr inbounds i8,i8*%ah,i64 8
%aj=bitcast i8*%ai to i8**
%ak=load i8*,i8**%aj,align 8
%al=icmp eq i8*%ak,null
br i1%al,label%am,label%au
am:
store i8*null,i8**%b,align 8
%an=call i8*@sml_alloc(i32 inreg 60)#0
%ao=getelementptr inbounds i8,i8*%an,i64 -4
%ap=bitcast i8*%ao to i32*
store i32 1342177336,i32*%ap,align 4
%aq=getelementptr inbounds i8,i8*%an,i64 56
%ar=bitcast i8*%aq to i32*
store i32 1,i32*%ar,align 4
%as=load i8*,i8**%c,align 8
%at=bitcast i8*%an to i8**
store i8*%as,i8**%at,align 8
call void@sml_raise(i8*inreg%an)#1
unreachable
au:
%av=bitcast i8*%ak to i32*
%aw=load i32,i32*%av,align 4
%ax=call fastcc i8*@_SMLFN16SMLSharp__Runtime9errorNameE(i32 inreg%aw)
%ay=call i32@sml_obj_equal(i8*inreg%ax,i8*inreg getelementptr inbounds(<{[4x i8],i32,[6x i8]}>,<{[4x i8],i32,[6x i8]}>*@a,i64 0,i32 2,i64 0))#0
%az=icmp eq i32%ay,0
br i1%az,label%aC,label%aA
aA:
store i8*null,i8**%c,align 8
%aB=add nsw i32%m,-1
br label%l
aC:
store i8*null,i8**%b,align 8
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
store i8*null,i8**%b,align 8
%aL=call i8*@sml_alloc(i32 inreg 60)#0
%aM=getelementptr inbounds i8,i8*%aL,i64 -4
%aN=bitcast i8*%aM to i32*
store i32 1342177336,i32*%aN,align 4
%aO=getelementptr inbounds i8,i8*%aL,i64 56
%aP=bitcast i8*%aO to i32*
store i32 1,i32*%aP,align 4
%aQ=load i8*,i8**%c,align 8
%aR=bitcast i8*%aL to i8**
store i8*%aQ,i8**%aR,align 8
call void@sml_raise(i8*inreg%aL)#1
unreachable
aS:
%aT=bitcast i8*%j to i8**
%aU=load i8*,i8**%aT,align 8
store i8*%aU,i8**%c,align 8
br label%aV
aV:
%aW=load i32,i32*@j,align 8
%aX=add nsw i32%aW,1
store i32%aX,i32*@j,align 8
%aY=call fastcc i8*@_SMLFN5Int323fmtE(i32 inreg 1)
%aZ=getelementptr inbounds i8,i8*%aY,i64 16
%a0=bitcast i8*%aZ to i8*(i8*,i8*)**
%a1=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%a0,align 8
%a2=bitcast i8*%aY to i8**
%a3=load i8*,i8**%a2,align 8
store i8*%a3,i8**%d,align 8
%a4=call i8*@sml_alloc(i32 inreg 4)#0
%a5=bitcast i8*%a4 to i32*
%a6=getelementptr inbounds i8,i8*%a4,i64 -4
%a7=bitcast i8*%a6 to i32*
store i32 4,i32*%a7,align 4
store i32%aW,i32*%a5,align 4
%a8=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%a9=call fastcc i8*%a1(i8*inreg%a8,i8*inreg%a4)
store i8*%a9,i8**%d,align 8
%ba=getelementptr inbounds i8,i8*%a9,i64 -4
%bb=bitcast i8*%ba to i32*
%bc=load i32,i32*%bb,align 4
%bd=and i32%bc,268435455
%be=icmp ugt i32%bd,6
br i1%be,label%bz,label%bf
bf:
%bg=call fastcc i8*@_SMLFN9StringCvt7padLeftE(i8 inreg 48)
%bh=getelementptr inbounds i8,i8*%bg,i64 16
%bi=bitcast i8*%bh to i8*(i8*,i8*)**
%bj=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bi,align 8
%bk=bitcast i8*%bg to i8**
%bl=load i8*,i8**%bk,align 8
store i8*%bl,i8**%e,align 8
%bm=call i8*@sml_alloc(i32 inreg 4)#0
%bn=bitcast i8*%bm to i32*
%bo=getelementptr inbounds i8,i8*%bm,i64 -4
%bp=bitcast i8*%bo to i32*
store i32 4,i32*%bp,align 4
store i32 6,i32*%bn,align 4
%bq=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%br=call fastcc i8*%bj(i8*inreg%bq,i8*inreg%bm)
%bs=getelementptr inbounds i8,i8*%br,i64 16
%bt=bitcast i8*%bs to i8*(i8*,i8*)**
%bu=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bt,align 8
%bv=bitcast i8*%br to i8**
%bw=load i8*,i8**%bv,align 8
%bx=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%by=call fastcc i8*%bu(i8*inreg%bw,i8*inreg%bx)
br label%bz
bz:
%bA=phi i8*[%by,%bf],[%a9,%aV]
store i8*%bA,i8**%d,align 8
%bB=load i8*,i8**%b,align 8
%bC=call i32@sml_obj_equal(i8*inreg%bB,i8*inreg getelementptr inbounds(<{[4x i8],i32,[1x i8]}>,<{[4x i8],i32,[1x i8]}>*@d,i64 0,i32 2,i64 0))#0
%bD=icmp eq i32%bC,0
br i1%bD,label%bE,label%bQ
bE:
%bF=call fastcc i8*@_SMLFN6String8isPrefixE(i8*inreg getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@e,i64 0,i32 2,i64 0))
%bG=getelementptr inbounds i8,i8*%bF,i64 16
%bH=bitcast i8*%bG to i8*(i8*,i8*)**
%bI=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bH,align 8
%bJ=bitcast i8*%bF to i8**
%bK=load i8*,i8**%bJ,align 8
%bL=load i8*,i8**%b,align 8
%bM=call fastcc i8*%bI(i8*inreg%bK,i8*inreg%bL)
%bN=bitcast i8*%bM to i32*
%bO=load i32,i32*%bN,align 4
%bP=icmp eq i32%bO,0
br i1%bP,label%b8,label%bQ
bQ:
%bR=call i8*@sml_alloc(i32 inreg 20)#0
%bS=getelementptr inbounds i8,i8*%bR,i64 -4
%bT=bitcast i8*%bS to i32*
store i32 1342177296,i32*%bT,align 4
%bU=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bV=bitcast i8*%bR to i8**
store i8*%bU,i8**%bV,align 8
%bW=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%bX=getelementptr inbounds i8,i8*%bR,i64 8
%bY=bitcast i8*%bX to i8**
store i8*%bW,i8**%bY,align 8
%bZ=getelementptr inbounds i8,i8*%bR,i64 16
%b0=bitcast i8*%bZ to i32*
store i32 3,i32*%b0,align 4
%b1=call fastcc i8*@_SMLFN6String1_ZE(i8*inreg%bR)
%b2=call fastcc i8*@_SMLFN8Filename10fromStringE(i8*inreg%b1)
store i8*%b2,i8**%b,align 8
%b3=call i8*@sml_alloc(i32 inreg 20)#0
%b4=getelementptr inbounds i8,i8*%b3,i64 -4
%b5=bitcast i8*%b4 to i32*
store i32 1342177296,i32*%b5,align 4
%b6=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%b7=bitcast i8*%b3 to i8**
store i8*%b6,i8**%b7,align 8
br label%cN
b8:
%b9=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ca=call fastcc i8*@_SMLFN8Filename10fromStringE(i8*inreg%b9)
store i8*%ca,i8**%d,align 8
%cb=call i8*@sml_alloc(i32 inreg 20)#0
%cc=getelementptr inbounds i8,i8*%cb,i64 -4
%cd=bitcast i8*%cc to i32*
store i32 1342177296,i32*%cd,align 4
%ce=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%cf=bitcast i8*%cb to i8**
store i8*%ce,i8**%cf,align 8
%cg=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ch=getelementptr inbounds i8,i8*%cb,i64 8
%ci=bitcast i8*%ch to i8**
store i8*%cg,i8**%ci,align 8
%cj=getelementptr inbounds i8,i8*%cb,i64 16
%ck=bitcast i8*%cj to i32*
store i32 3,i32*%ck,align 4
%cl=call fastcc i8*@_SMLFN8Filename10concatPathE(i8*inreg%cb)
store i8*%cl,i8**%c,align 8
call fastcc void@_SMLFN9CoreUtils5mkdirE(i8*inreg%cl)
%cm=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL49,i64 0,i32 2),align 8
store i8*%cm,i8**%d,align 8
%cn=call i8*@sml_alloc(i32 inreg 20)#0
%co=getelementptr inbounds i8,i8*%cn,i64 -4
%cp=bitcast i8*%co to i32*
store i32 1342177296,i32*%cp,align 4
store i8*%cn,i8**%e,align 8
%cq=bitcast i8*%cn to i64*
store i64 0,i64*%cq,align 4
%cr=load i8*,i8**%c,align 8
%cs=getelementptr inbounds i8,i8*%cn,i64 8
%ct=bitcast i8*%cs to i8**
store i8*%cr,i8**%ct,align 8
%cu=getelementptr inbounds i8,i8*%cn,i64 16
%cv=bitcast i8*%cu to i32*
store i32 2,i32*%cv,align 4
%cw=call i8*@sml_alloc(i32 inreg 20)#0
%cx=getelementptr inbounds i8,i8*%cw,i64 -4
%cy=bitcast i8*%cx to i32*
store i32 1342177296,i32*%cy,align 4
%cz=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%cA=bitcast i8*%cw to i8**
store i8*%cz,i8**%cA,align 8
%cB=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%cC=getelementptr inbounds i8,i8*%cw,i64 8
%cD=bitcast i8*%cC to i8**
store i8*%cB,i8**%cD,align 8
%cE=getelementptr inbounds i8,i8*%cw,i64 16
%cF=bitcast i8*%cE to i32*
store i32 3,i32*%cF,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL49,i64 0,i32 2)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL49,i64 0,i32 2),i8*inreg%cw)#0
%cG=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%cH=call fastcc i8*@_SMLFN8Filename10fromStringE(i8*inreg%cG)
store i8*%cH,i8**%b,align 8
%cI=call i8*@sml_alloc(i32 inreg 20)#0
%cJ=getelementptr inbounds i8,i8*%cI,i64 -4
%cK=bitcast i8*%cJ to i32*
store i32 1342177296,i32*%cK,align 4
%cL=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%cM=bitcast i8*%cI to i8**
store i8*%cL,i8**%cM,align 8
br label%cN
cN:
%cO=phi i8*[%cI,%b8],[%b3,%bQ]
%cP=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%cQ=getelementptr inbounds i8,i8*%cO,i64 8
%cR=bitcast i8*%cQ to i8**
store i8*%cP,i8**%cR,align 8
%cS=getelementptr inbounds i8,i8*%cO,i64 16
%cT=bitcast i8*%cS to i32*
store i32 3,i32*%cT,align 4
%cU=call fastcc i8*@_SMLFN8Filename10concatPathE(i8*inreg%cO)
store i8*%cU,i8**%b,align 8
call fastcc void@_SMLFN9CoreUtils7newFileE(i8*inreg%cU)
%cV=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL49,i64 0,i32 2),align 8
store i8*%cV,i8**%c,align 8
%cW=call i8*@sml_alloc(i32 inreg 20)#0
%cX=getelementptr inbounds i8,i8*%cW,i64 -4
%cY=bitcast i8*%cX to i32*
store i32 1342177296,i32*%cY,align 4
store i8*%cW,i8**%d,align 8
%cZ=getelementptr inbounds i8,i8*%cW,i64 4
%c0=bitcast i8*%cZ to i32*
store i32 0,i32*%c0,align 1
%c1=bitcast i8*%cW to i32*
store i32 1,i32*%c1,align 4
%c2=load i8*,i8**%b,align 8
%c3=getelementptr inbounds i8,i8*%cW,i64 8
%c4=bitcast i8*%c3 to i8**
store i8*%c2,i8**%c4,align 8
%c5=getelementptr inbounds i8,i8*%cW,i64 16
%c6=bitcast i8*%c5 to i32*
store i32 2,i32*%c6,align 4
%c7=call i8*@sml_alloc(i32 inreg 20)#0
%c8=getelementptr inbounds i8,i8*%c7,i64 -4
%c9=bitcast i8*%c8 to i32*
store i32 1342177296,i32*%c9,align 4
%da=load i8*,i8**%d,align 8
%db=bitcast i8*%c7 to i8**
store i8*%da,i8**%db,align 8
%dc=load i8*,i8**%c,align 8
%dd=getelementptr inbounds i8,i8*%c7,i64 8
%de=bitcast i8*%dd to i8**
store i8*%dc,i8**%de,align 8
%df=getelementptr inbounds i8,i8*%c7,i64 16
%dg=bitcast i8*%df to i32*
store i32 3,i32*%dg,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL49,i64 0,i32 2)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL49,i64 0,i32 2),i8*inreg%c7)#0
%dh=load i8*,i8**%b,align 8
ret i8*%dh
}
define fastcc void@_SMLFN8TempFile7cleanupE(i32 inreg%a)#2 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
%c=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL49,i64 0,i32 2),align 8
store i8*%c,i8**%b,align 8
br label%d
d:
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%h,label%g
g:
call void@sml_check(i32 inreg%e)
br label%h
h:
%i=load i8*,i8**%b,align 8
%j=icmp eq i8*%i,null
br i1%j,label%k,label%A
k:
store i8*null,i8**%b,align 8
%l=call fastcc i8*@_SMLFN6Option3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 0,i32 inreg 4)
%m=getelementptr inbounds i8,i8*%l,i64 16
%n=bitcast i8*%m to i8*(i8*,i8*)**
%o=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%n,align 8
%p=bitcast i8*%l to i8**
%q=load i8*,i8**%p,align 8
%r=load i8*,i8**@_SMLZN9CoreUtils7rmdir__fE,align 8
%s=call fastcc i8*%o(i8*inreg%q,i8*inreg%r)
%t=getelementptr inbounds i8,i8*%s,i64 16
%u=bitcast i8*%t to i8*(i8*,i8*)**
%v=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%u,align 8
%w=bitcast i8*%s to i8**
%x=load i8*,i8**%w,align 8
%y=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL48,i64 0,i32 2),align 8
%z=call fastcc i8*%v(i8*inreg%x,i8*inreg%y)
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL48,i64 0,i32 2)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL48,i64 0,i32 2),i8*inreg null)#0
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL49,i64 0,i32 2)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL49,i64 0,i32 2),i8*inreg null)#0
store i32 0,i32*@j,align 8
ret void
A:
%B=bitcast i8*%i to i8**
%C=load i8*,i8**%B,align 8
%D=bitcast i8*%C to i32*
%E=load i32,i32*%D,align 4
%F=icmp eq i32%E,0
%G=getelementptr inbounds i8,i8*%C,i64 8
%H=bitcast i8*%G to i8**
%I=load i8*,i8**%H,align 8
%J=getelementptr inbounds i8,i8*%i,i64 8
%K=bitcast i8*%J to i8**
%L=load i8*,i8**%K,align 8
store i8*%L,i8**%b,align 8
br i1%F,label%O,label%M
M:
call fastcc void@_SMLFN9CoreUtils4rm__fE(i8*inreg%I)
br label%N
N:
br label%d
O:
call fastcc void@_SMLFN9CoreUtils7rmdir__fE(i8*inreg%I)
br label%N
}
define internal fastcc i8*@_SMLLLN8TempFile6createE_60(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN8TempFile6createE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN8TempFile7cleanupE_61(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
tail call fastcc void@_SMLFN8TempFile7cleanupE(i32 inreg undef)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
