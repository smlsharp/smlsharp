@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN16SMLSharp__Runtime6SysErrE=external local_unnamed_addr global i8*
@_SMLZN9CoreUtils7rmdir__fE=external local_unnamed_addr global i8*
@_SMLZ4Fail=external unnamed_addr constant i8*
@_SMLDN8TempFile6tmpDirE_47=private global<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1342177272,i8*null}>,align 8
@_SMLDN8TempFile8tmpFilesE_48=private global<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1342177272,i8*null}>,align 8
@a=private unnamed_addr constant<{[4x i8],i32,[6x i8]}><{[4x i8]zeroinitializer,i32 -2147483642,[6x i8]c"exist\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,[57x i8]}><{[4x i8]zeroinitializer,i32 -2147483591,[57x i8]c"src/compiler/libs/toolchain/main/TempFile.sml:27.17(812)\00"}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,[36x i8]}><{[4x i8]zeroinitializer,i32 -2147483612,[36x i8]c"failed to make temporally directory\00"}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,[1x i8]}><{[4x i8]zeroinitializer,i32 -2147483647,[1x i8]zeroinitializer}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c".\00"}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN8TempFile6createE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN8TempFile6createE_73 to void(...)*),i32 -2147483647}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(void(i32)*@_SMLFN8TempFile7cleanupE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN8TempFile7cleanupE_75 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN8TempFile6createE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@f,i64 0,i32 2)to i8*)
@_SMLZN8TempFile7cleanupE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@g,i64 0,i32 2)to i8*)
@h=private unnamed_addr global[3x i64][i64 2,i64 sub(i64 ptrtoint(i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN8TempFile6tmpDirE_47,i32 0,i32 0,i32 0),i32 8)to i64),i64 ptrtoint([3x i64]*@h to i64)),i64 sub(i64 ptrtoint(i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN8TempFile8tmpFilesE_48,i32 0,i32 0,i32 0),i32 8)to i64),i64 ptrtoint([3x i64]*@h to i64))]
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
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
store i8*%a,i8**%g,align 8
%k=load atomic i32,i32*@sml_check_flag unordered,align 4
%l=icmp eq i32%k,0
br i1%l,label%n,label%m
m:
call void@sml_check(i32 inreg%k)
br label%n
n:
%o=bitcast i8**%f to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%o)
call void@llvm.gcroot(i8**%f,i8*null)#0
%p=load atomic i32,i32*@sml_check_flag unordered,align 4
%q=icmp eq i32%p,0
br i1%q,label%s,label%r
r:
call void@sml_check(i32 inreg%p)
br label%s
s:
%t=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN8TempFile6tmpDirE_47,i64 0,i32 2),align 8
%u=icmp eq i8*%t,null
br i1%u,label%v,label%bb
v:
%w=bitcast i8**%d to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%w)
%x=bitcast i8**%e to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%x)
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
br label%y
y:
%z=phi i32[5,%v],[%aK,%aJ]
%A=load atomic i32,i32*@sml_check_flag unordered,align 4
%B=icmp eq i32%A,0
br i1%B,label%D,label%C
C:
call void@sml_check(i32 inreg%A)
br label%D
D:
%E=icmp eq i32%z,0
br i1%E,label%F,label%Z
F:
%G=load i8*,i8**@_SMLZ4Fail,align 8
store i8*%G,i8**%d,align 8
%H=call i8*@sml_alloc(i32 inreg 28)#0
%I=getelementptr inbounds i8,i8*%H,i64 -4
%J=bitcast i8*%I to i32*
store i32 1342177304,i32*%J,align 4
store i8*%H,i8**%e,align 8
%K=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%L=bitcast i8*%H to i8**
store i8*%K,i8**%L,align 8
%M=getelementptr inbounds i8,i8*%H,i64 8
%N=bitcast i8*%M to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[57x i8]}>,<{[4x i8],i32,[57x i8]}>*@b,i64 0,i32 2,i64 0),i8**%N,align 8
%O=getelementptr inbounds i8,i8*%H,i64 16
%P=bitcast i8*%O to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[36x i8]}>,<{[4x i8],i32,[36x i8]}>*@c,i64 0,i32 2,i64 0),i8**%P,align 8
%Q=getelementptr inbounds i8,i8*%H,i64 24
%R=bitcast i8*%Q to i32*
store i32 7,i32*%R,align 4
%S=call i8*@sml_alloc(i32 inreg 60)#0
%T=getelementptr inbounds i8,i8*%S,i64 -4
%U=bitcast i8*%T to i32*
store i32 1342177336,i32*%U,align 4
%V=getelementptr inbounds i8,i8*%S,i64 56
%W=bitcast i8*%V to i32*
store i32 1,i32*%W,align 4
%X=load i8*,i8**%e,align 8
%Y=bitcast i8*%S to i8**
store i8*%X,i8**%Y,align 8
call void@sml_raise(i8*inreg%S)#1
unreachable
Z:
%aa=call fastcc i8*@_SMLFN18SMLSharp__OSFileSys7tmpNameE(i32 inreg 0)
%ab=call fastcc i8*@_SMLFN8Filename10fromStringE(i8*inreg%aa)
store i8*%ab,i8**%d,align 8
invoke fastcc void@_SMLFN9CoreUtils4rm__fE(i8*inreg%ab)
to label%ac unwind label%ae
ac:
%ad=load i8*,i8**%d,align 8
invoke fastcc void@_SMLFN9CoreUtils5mkdirE(i8*inreg%ad)
to label%a1 unwind label%ae
ae:
%af=landingpad{i8*,i8*}
catch i8*null
%ag=extractvalue{i8*,i8*}%af,1
%ah=bitcast i8*%ag to i8**
%ai=load i8*,i8**%ah,align 8
store i8*%ai,i8**%d,align 8
%aj=bitcast i8*%ai to i8**
%ak=load i8*,i8**%aj,align 8
%al=load i8*,i8**@_SMLZN16SMLSharp__Runtime6SysErrE,align 8
%am=icmp eq i8*%ak,%al
br i1%am,label%an,label%aT
an:
%ao=getelementptr inbounds i8,i8*%ai,i64 16
%ap=bitcast i8*%ao to i8**
%aq=load i8*,i8**%ap,align 8
%ar=getelementptr inbounds i8,i8*%aq,i64 8
%as=bitcast i8*%ar to i8**
%at=load i8*,i8**%as,align 8
%au=icmp eq i8*%at,null
br i1%au,label%av,label%aD
av:
%aw=call i8*@sml_alloc(i32 inreg 60)#0
%ax=getelementptr inbounds i8,i8*%aw,i64 -4
%ay=bitcast i8*%ax to i32*
store i32 1342177336,i32*%ay,align 4
%az=getelementptr inbounds i8,i8*%aw,i64 56
%aA=bitcast i8*%az to i32*
store i32 1,i32*%aA,align 4
%aB=load i8*,i8**%d,align 8
%aC=bitcast i8*%aw to i8**
store i8*%aB,i8**%aC,align 8
call void@sml_raise(i8*inreg%aw)#1
unreachable
aD:
%aE=bitcast i8*%at to i32*
%aF=load i32,i32*%aE,align 4
%aG=call fastcc i8*@_SMLFN16SMLSharp__Runtime9errorNameE(i32 inreg%aF)
%aH=call i32@sml_obj_equal(i8*inreg%aG,i8*inreg getelementptr inbounds(<{[4x i8],i32,[6x i8]}>,<{[4x i8],i32,[6x i8]}>*@a,i64 0,i32 2,i64 0))#0
%aI=icmp eq i32%aH,0
br i1%aI,label%aL,label%aJ
aJ:
store i8*null,i8**%d,align 8
%aK=add nsw i32%z,-1
br label%y
aL:
%aM=call i8*@sml_alloc(i32 inreg 60)#0
%aN=getelementptr inbounds i8,i8*%aM,i64 -4
%aO=bitcast i8*%aN to i32*
store i32 1342177336,i32*%aO,align 4
%aP=getelementptr inbounds i8,i8*%aM,i64 56
%aQ=bitcast i8*%aP to i32*
store i32 1,i32*%aQ,align 4
%aR=load i8*,i8**%d,align 8
%aS=bitcast i8*%aM to i8**
store i8*%aR,i8**%aS,align 8
call void@sml_raise(i8*inreg%aM)#1
unreachable
aT:
%aU=call i8*@sml_alloc(i32 inreg 60)#0
%aV=getelementptr inbounds i8,i8*%aU,i64 -4
%aW=bitcast i8*%aV to i32*
store i32 1342177336,i32*%aW,align 4
%aX=getelementptr inbounds i8,i8*%aU,i64 56
%aY=bitcast i8*%aX to i32*
store i32 1,i32*%aY,align 4
%aZ=load i8*,i8**%d,align 8
%a0=bitcast i8*%aU to i8**
store i8*%aZ,i8**%a0,align 8
call void@sml_raise(i8*inreg%aU)#1
unreachable
a1:
%a2=load i8*,i8**%d,align 8
call void@llvm.lifetime.end.p0i8(i64 8,i8*%w)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%x)
store i8*%a2,i8**%f,align 8
%a3=call i8*@sml_alloc(i32 inreg 12)#0
%a4=getelementptr inbounds i8,i8*%a3,i64 -4
%a5=bitcast i8*%a4 to i32*
store i32 1342177288,i32*%a5,align 4
%a6=load i8*,i8**%f,align 8
%a7=bitcast i8*%a3 to i8**
store i8*%a6,i8**%a7,align 8
%a8=getelementptr inbounds i8,i8*%a3,i64 8
%a9=bitcast i8*%a8 to i32*
store i32 1,i32*%a9,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN8TempFile6tmpDirE_47,i64 0,i32 2)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN8TempFile6tmpDirE_47,i64 0,i32 2),i8*inreg%a3)#0
%ba=load i8*,i8**%f,align 8
call void@llvm.lifetime.end.p0i8(i64 8,i8*%o)
br label%be
bb:
%bc=bitcast i8*%t to i8**
%bd=load i8*,i8**%bc,align 8
call void@llvm.lifetime.end.p0i8(i64 8,i8*%o)
br label%be
be:
%bf=phi i8*[%ba,%a1],[%bd,%bb]
store i8*%bf,i8**%h,align 8
%bg=bitcast i8**%b to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%bg)
%bh=bitcast i8**%c to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%bh)
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
%bi=load atomic i32,i32*@sml_check_flag unordered,align 4
%bj=icmp eq i32%bi,0
br i1%bj,label%bl,label%bk
bk:
call void@sml_check(i32 inreg%bi)
br label%bl
bl:
%bm=load i32,i32*@j,align 8
%bn=add nsw i32%bm,1
store i32%bn,i32*@j,align 8
%bo=call fastcc i8*@_SMLFN5Int323fmtE(i32 inreg 1)
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
store i32%bm,i32*%bv,align 4
%by=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%bz=call fastcc i8*%br(i8*inreg%by,i8*inreg%bu)
store i8*%bz,i8**%b,align 8
%bA=getelementptr inbounds i8,i8*%bz,i64 -4
%bB=bitcast i8*%bA to i32*
%bC=load i32,i32*%bB,align 4
%bD=and i32%bC,268435455
%bE=icmp ugt i32%bD,6
br i1%bE,label%bZ,label%bF
bF:
%bG=call fastcc i8*@_SMLFN9StringCvt7padLeftE(i8 inreg 48)
%bH=getelementptr inbounds i8,i8*%bG,i64 16
%bI=bitcast i8*%bH to i8*(i8*,i8*)**
%bJ=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bI,align 8
%bK=bitcast i8*%bG to i8**
%bL=load i8*,i8**%bK,align 8
store i8*%bL,i8**%c,align 8
%bM=call i8*@sml_alloc(i32 inreg 4)#0
%bN=bitcast i8*%bM to i32*
%bO=getelementptr inbounds i8,i8*%bM,i64 -4
%bP=bitcast i8*%bO to i32*
store i32 4,i32*%bP,align 4
store i32 6,i32*%bN,align 4
%bQ=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bR=call fastcc i8*%bJ(i8*inreg%bQ,i8*inreg%bM)
%bS=getelementptr inbounds i8,i8*%bR,i64 16
%bT=bitcast i8*%bS to i8*(i8*,i8*)**
%bU=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bT,align 8
%bV=bitcast i8*%bR to i8**
%bW=load i8*,i8**%bV,align 8
%bX=load i8*,i8**%b,align 8
%bY=call fastcc i8*%bU(i8*inreg%bW,i8*inreg%bX)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%bg)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%bh)
br label%b0
bZ:
call void@llvm.lifetime.end.p0i8(i64 8,i8*%bg)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%bh)
br label%b0
b0:
%b1=phi i8*[%bY,%bF],[%bz,%bZ]
store i8*%b1,i8**%i,align 8
%b2=load i8*,i8**%g,align 8
%b3=call i32@sml_obj_equal(i8*inreg%b2,i8*inreg getelementptr inbounds(<{[4x i8],i32,[1x i8]}>,<{[4x i8],i32,[1x i8]}>*@d,i64 0,i32 2,i64 0))#0
%b4=icmp eq i32%b3,0
br i1%b4,label%b5,label%ch
b5:
%b6=call fastcc i8*@_SMLFN6String8isPrefixE(i8*inreg getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@e,i64 0,i32 2,i64 0))
%b7=getelementptr inbounds i8,i8*%b6,i64 16
%b8=bitcast i8*%b7 to i8*(i8*,i8*)**
%b9=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%b8,align 8
%ca=bitcast i8*%b6 to i8**
%cb=load i8*,i8**%ca,align 8
%cc=load i8*,i8**%g,align 8
%cd=call fastcc i8*%b9(i8*inreg%cb,i8*inreg%cc)
%ce=bitcast i8*%cd to i32*
%cf=load i32,i32*%ce,align 4
%cg=icmp eq i32%cf,0
br i1%cg,label%cz,label%ch
ch:
%ci=call i8*@sml_alloc(i32 inreg 20)#0
%cj=getelementptr inbounds i8,i8*%ci,i64 -4
%ck=bitcast i8*%cj to i32*
store i32 1342177296,i32*%ck,align 4
%cl=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%cm=bitcast i8*%ci to i8**
store i8*%cl,i8**%cm,align 8
%cn=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%co=getelementptr inbounds i8,i8*%ci,i64 8
%cp=bitcast i8*%co to i8**
store i8*%cn,i8**%cp,align 8
%cq=getelementptr inbounds i8,i8*%ci,i64 16
%cr=bitcast i8*%cq to i32*
store i32 3,i32*%cr,align 4
%cs=call fastcc i8*@_SMLFN6String1_ZE(i8*inreg%ci)
%ct=call fastcc i8*@_SMLFN8Filename10fromStringE(i8*inreg%cs)
store i8*%ct,i8**%g,align 8
%cu=call i8*@sml_alloc(i32 inreg 20)#0
%cv=getelementptr inbounds i8,i8*%cu,i64 -4
%cw=bitcast i8*%cv to i32*
store i32 1342177296,i32*%cw,align 4
%cx=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%cy=bitcast i8*%cu to i8**
store i8*%cx,i8**%cy,align 8
br label%de
cz:
%cA=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%cB=call fastcc i8*@_SMLFN8Filename10fromStringE(i8*inreg%cA)
store i8*%cB,i8**%i,align 8
%cC=call i8*@sml_alloc(i32 inreg 20)#0
%cD=getelementptr inbounds i8,i8*%cC,i64 -4
%cE=bitcast i8*%cD to i32*
store i32 1342177296,i32*%cE,align 4
%cF=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%cG=bitcast i8*%cC to i8**
store i8*%cF,i8**%cG,align 8
%cH=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%cI=getelementptr inbounds i8,i8*%cC,i64 8
%cJ=bitcast i8*%cI to i8**
store i8*%cH,i8**%cJ,align 8
%cK=getelementptr inbounds i8,i8*%cC,i64 16
%cL=bitcast i8*%cK to i32*
store i32 3,i32*%cL,align 4
%cM=call fastcc i8*@_SMLFN8Filename10concatPathE(i8*inreg%cC)
store i8*%cM,i8**%h,align 8
call fastcc void@_SMLFN9CoreUtils5mkdirE(i8*inreg%cM)
%cN=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN8TempFile8tmpFilesE_48,i64 0,i32 2),align 8
store i8*%cN,i8**%i,align 8
%cO=call i8*@sml_alloc(i32 inreg 20)#0
%cP=getelementptr inbounds i8,i8*%cO,i64 -4
%cQ=bitcast i8*%cP to i32*
store i32 1342177296,i32*%cQ,align 4
store i8*%cO,i8**%j,align 8
%cR=bitcast i8*%cO to i64*
store i64 0,i64*%cR,align 4
%cS=load i8*,i8**%h,align 8
%cT=getelementptr inbounds i8,i8*%cO,i64 8
%cU=bitcast i8*%cT to i8**
store i8*%cS,i8**%cU,align 8
%cV=getelementptr inbounds i8,i8*%cO,i64 16
%cW=bitcast i8*%cV to i32*
store i32 2,i32*%cW,align 4
%cX=call i8*@sml_alloc(i32 inreg 20)#0
%cY=getelementptr inbounds i8,i8*%cX,i64 -4
%cZ=bitcast i8*%cY to i32*
store i32 1342177296,i32*%cZ,align 4
%c0=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%c1=bitcast i8*%cX to i8**
store i8*%c0,i8**%c1,align 8
%c2=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%c3=getelementptr inbounds i8,i8*%cX,i64 8
%c4=bitcast i8*%c3 to i8**
store i8*%c2,i8**%c4,align 8
%c5=getelementptr inbounds i8,i8*%cX,i64 16
%c6=bitcast i8*%c5 to i32*
store i32 3,i32*%c6,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN8TempFile8tmpFilesE_48,i64 0,i32 2)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN8TempFile8tmpFilesE_48,i64 0,i32 2),i8*inreg%cX)#0
%c7=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%c8=call fastcc i8*@_SMLFN8Filename10fromStringE(i8*inreg%c7)
store i8*%c8,i8**%g,align 8
%c9=call i8*@sml_alloc(i32 inreg 20)#0
%da=getelementptr inbounds i8,i8*%c9,i64 -4
%db=bitcast i8*%da to i32*
store i32 1342177296,i32*%db,align 4
%dc=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%dd=bitcast i8*%c9 to i8**
store i8*%dc,i8**%dd,align 8
br label%de
de:
%df=phi i8*[%c9,%cz],[%cu,%ch]
%dg=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%dh=getelementptr inbounds i8,i8*%df,i64 8
%di=bitcast i8*%dh to i8**
store i8*%dg,i8**%di,align 8
%dj=getelementptr inbounds i8,i8*%df,i64 16
%dk=bitcast i8*%dj to i32*
store i32 3,i32*%dk,align 4
%dl=call fastcc i8*@_SMLFN8Filename10concatPathE(i8*inreg%df)
store i8*%dl,i8**%g,align 8
call fastcc void@_SMLFN9CoreUtils7newFileE(i8*inreg%dl)
%dm=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN8TempFile8tmpFilesE_48,i64 0,i32 2),align 8
store i8*%dm,i8**%h,align 8
%dn=call i8*@sml_alloc(i32 inreg 20)#0
%do=getelementptr inbounds i8,i8*%dn,i64 -4
%dp=bitcast i8*%do to i32*
store i32 1342177296,i32*%dp,align 4
store i8*%dn,i8**%i,align 8
%dq=getelementptr inbounds i8,i8*%dn,i64 4
%dr=bitcast i8*%dq to i32*
store i32 0,i32*%dr,align 1
%ds=bitcast i8*%dn to i32*
store i32 1,i32*%ds,align 4
%dt=load i8*,i8**%g,align 8
%du=getelementptr inbounds i8,i8*%dn,i64 8
%dv=bitcast i8*%du to i8**
store i8*%dt,i8**%dv,align 8
%dw=getelementptr inbounds i8,i8*%dn,i64 16
%dx=bitcast i8*%dw to i32*
store i32 2,i32*%dx,align 4
%dy=call i8*@sml_alloc(i32 inreg 20)#0
%dz=getelementptr inbounds i8,i8*%dy,i64 -4
%dA=bitcast i8*%dz to i32*
store i32 1342177296,i32*%dA,align 4
%dB=load i8*,i8**%i,align 8
%dC=bitcast i8*%dy to i8**
store i8*%dB,i8**%dC,align 8
%dD=load i8*,i8**%h,align 8
%dE=getelementptr inbounds i8,i8*%dy,i64 8
%dF=bitcast i8*%dE to i8**
store i8*%dD,i8**%dF,align 8
%dG=getelementptr inbounds i8,i8*%dy,i64 16
%dH=bitcast i8*%dG to i32*
store i32 3,i32*%dH,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN8TempFile8tmpFilesE_48,i64 0,i32 2)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN8TempFile8tmpFilesE_48,i64 0,i32 2),i8*inreg%dy)#0
%dI=load i8*,i8**%g,align 8
ret i8*%dI
}
define fastcc void@_SMLFN8TempFile7cleanupE(i32 inreg%a)#2 gc"smlsharp"{
%b=alloca i8*,align 8
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
tail call void@sml_check(i32 inreg%c)
br label%f
f:
%g=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN8TempFile8tmpFilesE_48,i64 0,i32 2),align 8
%h=bitcast i8**%b to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%h)
call void@llvm.gcroot(i8**%b,i8*null)#0
br label%i
i:
%j=phi i8*[%F,%B],[%g,%f]
store i8*%j,i8**%b,align 8
%k=load atomic i32,i32*@sml_check_flag unordered,align 4
%l=icmp eq i32%k,0
br i1%l,label%o,label%m
m:
call void@sml_check(i32 inreg%k)
%n=load i8*,i8**%b,align 8
br label%o
o:
%p=phi i8*[%n,%m],[%j,%i]
%q=icmp eq i8*%p,null
br i1%q,label%H,label%r
r:
%s=bitcast i8*%p to i8**
%t=load i8*,i8**%s,align 8
%u=bitcast i8*%t to i32*
%v=load i32,i32*%u,align 4
%w=icmp eq i32%v,0
%x=getelementptr inbounds i8,i8*%t,i64 8
%y=bitcast i8*%x to i8**
%z=load i8*,i8**%y,align 8
br i1%w,label%G,label%A
A:
call fastcc void@_SMLFN9CoreUtils4rm__fE(i8*inreg%z)
br label%B
B:
%C=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%D=getelementptr inbounds i8,i8*%C,i64 8
%E=bitcast i8*%D to i8**
%F=load i8*,i8**%E,align 8
br label%i
G:
call fastcc void@_SMLFN9CoreUtils7rmdir__fE(i8*inreg%z)
br label%B
H:
call void@llvm.lifetime.end.p0i8(i64 8,i8*%h)
%I=call fastcc i8*@_SMLFN6Option3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 0,i32 inreg 4)
%J=getelementptr inbounds i8,i8*%I,i64 16
%K=bitcast i8*%J to i8*(i8*,i8*)**
%L=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%K,align 8
%M=bitcast i8*%I to i8**
%N=load i8*,i8**%M,align 8
%O=load i8*,i8**@_SMLZN9CoreUtils7rmdir__fE,align 8
%P=call fastcc i8*%L(i8*inreg%N,i8*inreg%O)
%Q=getelementptr inbounds i8,i8*%P,i64 16
%R=bitcast i8*%Q to i8*(i8*,i8*)**
%S=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%R,align 8
%T=bitcast i8*%P to i8**
%U=load i8*,i8**%T,align 8
%V=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN8TempFile6tmpDirE_47,i64 0,i32 2),align 8
%W=call fastcc i8*%S(i8*inreg%U,i8*inreg%V)
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN8TempFile6tmpDirE_47,i64 0,i32 2)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN8TempFile6tmpDirE_47,i64 0,i32 2),i8*inreg null)#0
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN8TempFile8tmpFilesE_48,i64 0,i32 2)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN8TempFile8tmpFilesE_48,i64 0,i32 2),i8*inreg null)#0
store i32 0,i32*@j,align 8
ret void
}
define internal fastcc i8*@_SMLLN8TempFile6createE_73(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN8TempFile6createE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLN8TempFile7cleanupE_75(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
tail call fastcc void@_SMLFN8TempFile7cleanupE(i32 inreg undef)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
declare void@llvm.lifetime.start.p0i8(i64,i8*)#0
declare void@llvm.lifetime.end.p0i8(i64,i8*)#0
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
