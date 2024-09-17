@sml_check_flag=external local_unnamed_addr global i32
@_SMLZ9Subscript=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[17x i8]}><{[4x i8]zeroinitializer,i32 -2147483631,[17x i8]c"UserFileMap.Load\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[17x i8]}>,<{[4x i8],i32,[17x i8]}>*@a,i32 0,i32 0,i32 0),i32 8),i32 9,[4x i8]zeroinitializer,i32 1}>,align 8
@_SMLDL81=private constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@b,i32 0,i32 0,i32 0),i32 8)}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,[65x i8]}><{[4x i8]zeroinitializer,i32 -2147483583,[65x i8]c"src/compiler/compilePhases/main/main/UserFileMap.sml:52.31(1460)\00"}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,[65x i8]}><{[4x i8]zeroinitializer,i32 -2147483583,[65x i8]c"src/compiler/compilePhases/main/main/UserFileMap.sml:58.42(1656)\00"}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[65x i8]}><{[4x i8]zeroinitializer,i32 -2147483583,[65x i8]c"src/compiler/compilePhases/main/main/UserFileMap.sml:62.37(1776)\00"}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,[65x i8]}><{[4x i8]zeroinitializer,i32 -2147483583,[65x i8]c"src/compiler/compilePhases/main/main/UserFileMap.sml:67.14(1924)\00"}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,[25x i8]}><{[4x i8]zeroinitializer,i32 -2147483623,[25x i8]c"unexpected character -- \00"}>,align 8
@h=private unnamed_addr constant<{[4x i8],i32,[23x i8]}><{[4x i8]zeroinitializer,i32 -2147483625,[23x i8]c"unexpected end of line\00"}>,align 8
@i=private unnamed_addr constant<{[4x i8],i32,[22x i8]}><{[4x i8]zeroinitializer,i32 -2147483626,[22x i8]c"illegal operation -- \00"}>,align 8
@j=private unnamed_addr constant<{[4x i8],i32,[64x i8]}><{[4x i8]zeroinitializer,i32 -2147483584,[64x i8]c"src/compiler/compilePhases/main/main/UserFileMap.sml:13.12(260)\00"}>,align 8
@_SMLZN11UserFileMap4LoadE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL81,i64 0,i32 2)to i8*)
@k=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN11UserFileMap4findE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11UserFileMap4findE_130 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN11UserFileMap4findE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@k,i64 0,i32 2)to i8*)
@_SML_gvar4640b8438598f26f_UserFileMap=private global<{[4x i8],i32,[2x i8*]}><{[4x i8]zeroinitializer,i32 -1342177264,[2x i8*]zeroinitializer}>,align 8
@l=private unnamed_addr global[2x i64][i64 1,i64 sub(i64 ptrtoint(i8**getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar4640b8438598f26f_UserFileMap,i32 0,i32 2,i32 0)to i64),i64 ptrtoint([2x i64]*@l to i64))]
@_SML_ftab4640b8438598f26f_UserFileMap=external global i8
@m=private unnamed_addr global i8 0
@_SMLZN11UserFileMap4loadE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar4640b8438598f26f_UserFileMap,i32 0,i32 2,i32 0)
@_SMLZN11UserFileMap8fromListE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar4640b8438598f26f_UserFileMap,i32 0,i32 2,i32 1)
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_end()local_unnamed_addr#0
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i32@sml_personality(...)#0
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare void@sml_save_exn(i8*inreg)local_unnamed_addr#0
declare void@sml_start(i8*inreg)local_unnamed_addr#0
declare void@sml_write(i8*inreg,i8**inreg,i8*inreg)local_unnamed_addr#0
declare i32@_SMLFN4Char7isSpaceE(i8 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List5foldlE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN6String1_ZE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN6String3strE(i8 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN6String9substringE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SMLFN6TextIO7closeInE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN6TextIO9inputLineE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN8Filename10componentsE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN8Filename10fromStringE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN8Filename3Map4findE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN8Filename3Map5emptyE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN8Filename3Map6insertE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN8Filename6TextIO6openInE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maince7036f3433e1102_Char()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main03d87556ec7f64b2_List()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main1ef93e13728790b1_String()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main3446b7b079949ccf_text_io()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maine29d9c3af819282f_Filename()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_loadce7036f3433e1102_Char(i8*)local_unnamed_addr
declare void@_SML_load03d87556ec7f64b2_List(i8*)local_unnamed_addr
declare void@_SML_load1ef93e13728790b1_String(i8*)local_unnamed_addr
declare void@_SML_load3446b7b079949ccf_text_io(i8*)local_unnamed_addr
declare void@_SML_loade29d9c3af819282f_Filename(i8*)local_unnamed_addr
define private void@_SML_tabb4640b8438598f26f_UserFileMap()#3{
unreachable
}
define void@_SML_load4640b8438598f26f_UserFileMap(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@m,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@m,align 1
tail call void@_SML_loadce7036f3433e1102_Char(i8*%a)#0
tail call void@_SML_load03d87556ec7f64b2_List(i8*%a)#0
tail call void@_SML_load1ef93e13728790b1_String(i8*%a)#0
tail call void@_SML_load3446b7b079949ccf_text_io(i8*%a)#0
tail call void@_SML_loade29d9c3af819282f_Filename(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb4640b8438598f26f_UserFileMap,i8*@_SML_ftab4640b8438598f26f_UserFileMap,i8*bitcast([2x i64]*@l to i8*))#0
ret void
}
define void@_SML_main4640b8438598f26f_UserFileMap()local_unnamed_addr#2 gc"smlsharp"personality i32(...)*@sml_personality{
%a=alloca[3x i8*],align 8
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=load i8,i8*@m,align 1
%g=and i8%f,2
%h=icmp eq i8%g,0
br i1%h,label%j,label%i
i:
ret void
j:
store i8 3,i8*@m,align 1
tail call void@_SML_maince7036f3433e1102_Char()#2
tail call void@_SML_main03d87556ec7f64b2_List()#2
tail call void@_SML_main1ef93e13728790b1_String()#2
tail call void@_SML_main3446b7b079949ccf_text_io()#2
tail call void@_SML_maine29d9c3af819282f_Filename()#2
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
%k=bitcast[3x i8*]*%a to i8*
call void@sml_start(i8*inreg%k)#0
%l=load atomic i32,i32*@sml_check_flag unordered,align 4
%m=icmp eq i32%l,0
br i1%m,label%o,label%n
n:
invoke void@sml_check(i32 inreg%l)
to label%o unwind label%a1
o:
%p=invoke fastcc i8*@_SMLFN8Filename3Map5emptyE(i32 inreg 1,i32 inreg 8)
to label%q unwind label%a1
q:
store i8*%p,i8**%b,align 8
%r=call i8*@sml_alloc(i32 inreg 20)#0
%s=getelementptr inbounds i8,i8*%r,i64 -4
%t=bitcast i8*%s to i32*
store i32 1342177296,i32*%t,align 4
store i8*%r,i8**%c,align 8
%u=bitcast i8*%r to i8**
store i8*null,i8**%u,align 8
%v=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%w=getelementptr inbounds i8,i8*%r,i64 8
%x=bitcast i8*%w to i8**
store i8*%v,i8**%x,align 8
%y=getelementptr inbounds i8,i8*%r,i64 16
%z=bitcast i8*%y to i32*
store i32 3,i32*%z,align 4
%A=call i8*@sml_alloc(i32 inreg 12)#0
%B=getelementptr inbounds i8,i8*%A,i64 -4
%C=bitcast i8*%B to i32*
store i32 1342177288,i32*%C,align 4
store i8*%A,i8**%b,align 8
%D=load i8*,i8**%c,align 8
%E=bitcast i8*%A to i8**
store i8*%D,i8**%E,align 8
%F=getelementptr inbounds i8,i8*%A,i64 8
%G=bitcast i8*%F to i32*
store i32 1,i32*%G,align 4
%H=call i8*@sml_alloc(i32 inreg 28)#0
%I=getelementptr inbounds i8,i8*%H,i64 -4
%J=bitcast i8*%I to i32*
store i32 1342177304,i32*%J,align 4
%K=load i8*,i8**%b,align 8
%L=bitcast i8*%H to i8**
store i8*%K,i8**%L,align 8
%M=getelementptr inbounds i8,i8*%H,i64 8
%N=bitcast i8*%M to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11UserFileMap3addE_82 to void(...)*),void(...)**%N,align 8
%O=getelementptr inbounds i8,i8*%H,i64 16
%P=bitcast i8*%O to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11UserFileMap3addE_82 to void(...)*),void(...)**%P,align 8
%Q=getelementptr inbounds i8,i8*%H,i64 24
%R=bitcast i8*%Q to i32*
store i32 -2147483647,i32*%R,align 4
%S=call i8*@sml_alloc(i32 inreg 20)#0
%T=getelementptr inbounds i8,i8*%S,i64 -4
%U=bitcast i8*%T to i32*
store i32 1342177296,i32*%U,align 4
store i8*%S,i8**%d,align 8
%V=load i8*,i8**%c,align 8
%W=bitcast i8*%S to i8**
store i8*%V,i8**%W,align 8
%X=load i8*,i8**%b,align 8
%Y=getelementptr inbounds i8,i8*%S,i64 8
%Z=bitcast i8*%Y to i8**
store i8*%X,i8**%Z,align 8
%aa=getelementptr inbounds i8,i8*%S,i64 16
%ab=bitcast i8*%aa to i32*
store i32 3,i32*%ab,align 4
%ac=call i8*@sml_alloc(i32 inreg 28)#0
%ad=getelementptr inbounds i8,i8*%ac,i64 -4
%ae=bitcast i8*%ad to i32*
store i32 1342177304,i32*%ae,align 4
store i8*%ac,i8**%e,align 8
%af=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ag=bitcast i8*%ac to i8**
store i8*%af,i8**%ag,align 8
%ah=getelementptr inbounds i8,i8*%ac,i64 8
%ai=bitcast i8*%ah to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11UserFileMap8fromListE_84 to void(...)*),void(...)**%ai,align 8
%aj=getelementptr inbounds i8,i8*%ac,i64 16
%ak=bitcast i8*%aj to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11UserFileMap8fromListE_84 to void(...)*),void(...)**%ak,align 8
%al=getelementptr inbounds i8,i8*%ac,i64 24
%am=bitcast i8*%al to i32*
store i32 -2147483647,i32*%am,align 4
%an=call i8*@sml_alloc(i32 inreg 12)#0
%ao=getelementptr inbounds i8,i8*%an,i64 -4
%ap=bitcast i8*%ao to i32*
store i32 1342177288,i32*%ap,align 4
store i8*%an,i8**%d,align 8
%aq=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%ar=bitcast i8*%an to i8**
store i8*%aq,i8**%ar,align 8
%as=getelementptr inbounds i8,i8*%an,i64 8
%at=bitcast i8*%as to i32*
store i32 1,i32*%at,align 4
%au=call i8*@sml_alloc(i32 inreg 28)#0
%av=getelementptr inbounds i8,i8*%au,i64 -4
%aw=bitcast i8*%av to i32*
store i32 1342177304,i32*%aw,align 4
%ax=load i8*,i8**%d,align 8
%ay=bitcast i8*%au to i8**
store i8*%ax,i8**%ay,align 8
%az=getelementptr inbounds i8,i8*%au,i64 8
%aA=bitcast i8*%az to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i32,i8*)*@_SMLLN11UserFileMap10parseLinesE_115 to void(...)*),void(...)**%aA,align 8
%aB=getelementptr inbounds i8,i8*%au,i64 16
%aC=bitcast i8*%aB to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*,i8*)*@_SMLLN11UserFileMap10parseLinesE_128 to void(...)*),void(...)**%aC,align 8
%aD=getelementptr inbounds i8,i8*%au,i64 24
%aE=bitcast i8*%aD to i32*
store i32 -2147483647,i32*%aE,align 4
%aF=call i8*@sml_alloc(i32 inreg 20)#0
%aG=getelementptr inbounds i8,i8*%aF,i64 -4
%aH=bitcast i8*%aG to i32*
store i32 1342177296,i32*%aH,align 4
store i8*%aF,i8**%b,align 8
%aI=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aJ=bitcast i8*%aF to i8**
store i8*%aI,i8**%aJ,align 8
%aK=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aL=getelementptr inbounds i8,i8*%aF,i64 8
%aM=bitcast i8*%aL to i8**
store i8*%aK,i8**%aM,align 8
%aN=getelementptr inbounds i8,i8*%aF,i64 16
%aO=bitcast i8*%aN to i32*
store i32 3,i32*%aO,align 4
%aP=call i8*@sml_alloc(i32 inreg 28)#0
%aQ=getelementptr inbounds i8,i8*%aP,i64 -4
%aR=bitcast i8*%aQ to i32*
store i32 1342177304,i32*%aR,align 4
%aS=load i8*,i8**%b,align 8
%aT=bitcast i8*%aP to i8**
store i8*%aS,i8**%aT,align 8
%aU=getelementptr inbounds i8,i8*%aP,i64 8
%aV=bitcast i8*%aU to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11UserFileMap4loadE_116 to void(...)*),void(...)**%aV,align 8
%aW=getelementptr inbounds i8,i8*%aP,i64 16
%aX=bitcast i8*%aW to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11UserFileMap4loadE_116 to void(...)*),void(...)**%aX,align 8
%aY=getelementptr inbounds i8,i8*%aP,i64 24
%aZ=bitcast i8*%aY to i32*
store i32 -2147483647,i32*%aZ,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar4640b8438598f26f_UserFileMap,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar4640b8438598f26f_UserFileMap,i64 0,i32 2,i64 0),i8*inreg%aP)#0
%a0=load i8*,i8**%e,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar4640b8438598f26f_UserFileMap,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar4640b8438598f26f_UserFileMap,i64 0,i32 2,i64 1),i8*inreg%a0)#0
call void@sml_end()#0
ret void
a1:
%a2=landingpad{i8*,i8*}
cleanup
%a3=extractvalue{i8*,i8*}%a2,1
call void@sml_save_exn(i8*inreg%a3)#0
call void@sml_end()#0
resume{i8*,i8*}%a2
}
define internal fastcc i8*@_SMLLN11UserFileMap3addE_82(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
q:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
store i8*%a,i8**%i,align 8
store i8*%b,i8**%c,align 8
%k=load atomic i32,i32*@sml_check_flag unordered,align 4
%l=icmp eq i32%k,0
br i1%l,label%o,label%m
m:
call void@sml_check(i32 inreg%k)
%n=load i8*,i8**%c,align 8
br label%o
o:
%p=phi i8*[%n,%m],[%b,%q]
%r=bitcast i8*%p to i8**
%s=load i8*,i8**%r,align 8
%t=bitcast i8*%s to i8**
%u=load i8*,i8**%t,align 8
%v=icmp eq i8*%u,null
br i1%v,label%w,label%ab
w:
%x=getelementptr inbounds i8,i8*%s,i64 8
%y=bitcast i8*%x to i8**
%z=load i8*,i8**%y,align 8
store i8*%z,i8**%c,align 8
%A=getelementptr inbounds i8,i8*%p,i64 8
%B=bitcast i8*%A to i8**
%C=load i8*,i8**%B,align 8
%D=icmp eq i8*%C,null
br i1%D,label%E,label%Z
E:
store i8*null,i8**%i,align 8
%F=getelementptr inbounds i8,i8*%p,i64 16
%G=bitcast i8*%F to i8**
%H=load i8*,i8**%G,align 8
store i8*%H,i8**%d,align 8
%I=call i8*@sml_alloc(i32 inreg 12)#0
%J=getelementptr inbounds i8,i8*%I,i64 -4
%K=bitcast i8*%J to i32*
store i32 1342177288,i32*%K,align 4
store i8*%I,i8**%e,align 8
%L=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%M=bitcast i8*%I to i8**
store i8*%L,i8**%M,align 8
%N=getelementptr inbounds i8,i8*%I,i64 8
%O=bitcast i8*%N to i32*
store i32 1,i32*%O,align 4
%P=call i8*@sml_alloc(i32 inreg 20)#0
%Q=getelementptr inbounds i8,i8*%P,i64 -4
%R=bitcast i8*%Q to i32*
store i32 1342177296,i32*%R,align 4
%S=load i8*,i8**%e,align 8
%T=bitcast i8*%P to i8**
store i8*%S,i8**%T,align 8
%U=load i8*,i8**%c,align 8
%V=getelementptr inbounds i8,i8*%P,i64 8
%W=bitcast i8*%V to i8**
store i8*%U,i8**%W,align 8
%X=getelementptr inbounds i8,i8*%P,i64 16
%Y=bitcast i8*%X to i32*
store i32 3,i32*%Y,align 4
ret i8*%P
Z:
%aa=load i8*,i8**%t,align 8
br label%al
ab:
%ac=getelementptr inbounds i8,i8*%p,i64 8
%ad=bitcast i8*%ac to i8**
%ae=load i8*,i8**%ad,align 8
%af=icmp eq i8*%ae,null
br i1%af,label%ag,label%ah
ag:
ret i8*%s
ah:
%ai=getelementptr inbounds i8,i8*%s,i64 8
%aj=bitcast i8*%ai to i8**
%ak=load i8*,i8**%aj,align 8
br label%al
al:
%am=phi i8*[%z,%Z],[%ak,%ah]
%an=phi i8*[%aa,%Z],[%u,%ah]
%ao=phi i8*[%C,%Z],[%ae,%ah]
%ap=getelementptr inbounds i8,i8*%p,i64 16
%aq=getelementptr inbounds i8,i8*%ao,i64 8
%ar=bitcast i8*%ap to i8**
%as=bitcast i8*%aq to i8**
%at=bitcast i8*%ao to i8**
%au=load i8*,i8**%ar,align 8
%av=load i8*,i8**%as,align 8
%aw=load i8*,i8**%at,align 8
store i8*%am,i8**%c,align 8
store i8*%an,i8**%d,align 8
store i8*%aw,i8**%e,align 8
store i8*%av,i8**%f,align 8
store i8*%au,i8**%g,align 8
%ax=call fastcc i8*@_SMLFN8Filename3Map4findE(i32 inreg 1,i32 inreg 8)
%ay=getelementptr inbounds i8,i8*%ax,i64 16
%az=bitcast i8*%ay to i8*(i8*,i8*)**
%aA=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%az,align 8
%aB=bitcast i8*%ax to i8**
%aC=load i8*,i8**%aB,align 8
store i8*%aC,i8**%h,align 8
%aD=call i8*@sml_alloc(i32 inreg 20)#0
%aE=getelementptr inbounds i8,i8*%aD,i64 -4
%aF=bitcast i8*%aE to i32*
store i32 1342177296,i32*%aF,align 4
%aG=load i8*,i8**%c,align 8
%aH=bitcast i8*%aD to i8**
store i8*%aG,i8**%aH,align 8
%aI=load i8*,i8**%e,align 8
%aJ=getelementptr inbounds i8,i8*%aD,i64 8
%aK=bitcast i8*%aJ to i8**
store i8*%aI,i8**%aK,align 8
%aL=getelementptr inbounds i8,i8*%aD,i64 16
%aM=bitcast i8*%aL to i32*
store i32 3,i32*%aM,align 4
%aN=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%aO=call fastcc i8*%aA(i8*inreg%aN,i8*inreg%aD)
%aP=icmp eq i8*%aO,null
%aQ=bitcast i8*%aO to i8**
%aR=bitcast i8**%i to i8***
%aS=load i8**,i8***%aR,align 8
%aT=select i1%aP,i8**%aS,i8**%aQ
%aU=load i8*,i8**%aT,align 8
store i8*%aU,i8**%h,align 8
%aV=call fastcc i8*@_SMLFN8Filename3Map6insertE(i32 inreg 1,i32 inreg 8)
%aW=getelementptr inbounds i8,i8*%aV,i64 16
%aX=bitcast i8*%aW to i8*(i8*,i8*)**
%aY=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aX,align 8
%aZ=bitcast i8*%aV to i8**
%a0=load i8*,i8**%aZ,align 8
store i8*%a0,i8**%j,align 8
%a1=call i8*@sml_alloc(i32 inreg 28)#0
%a2=getelementptr inbounds i8,i8*%a1,i64 -4
%a3=bitcast i8*%a2 to i32*
store i32 1342177304,i32*%a3,align 4
%a4=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%a5=bitcast i8*%a1 to i8**
store i8*%a4,i8**%a5,align 8
%a6=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%a7=getelementptr inbounds i8,i8*%a1,i64 8
%a8=bitcast i8*%a7 to i8**
store i8*%a6,i8**%a8,align 8
%a9=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%ba=getelementptr inbounds i8,i8*%a1,i64 16
%bb=bitcast i8*%ba to i8**
store i8*%a9,i8**%bb,align 8
%bc=getelementptr inbounds i8,i8*%a1,i64 24
%bd=bitcast i8*%bc to i32*
store i32 7,i32*%bd,align 4
%be=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%bf=call fastcc i8*@_SMLLN11UserFileMap3addE_82(i8*inreg%be,i8*inreg%a1)
store i8*%bf,i8**%f,align 8
%bg=call i8*@sml_alloc(i32 inreg 28)#0
%bh=getelementptr inbounds i8,i8*%bg,i64 -4
%bi=bitcast i8*%bh to i32*
store i32 1342177304,i32*%bi,align 4
%bj=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bk=bitcast i8*%bg to i8**
store i8*%bj,i8**%bk,align 8
%bl=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bm=getelementptr inbounds i8,i8*%bg,i64 8
%bn=bitcast i8*%bm to i8**
store i8*%bl,i8**%bn,align 8
%bo=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bp=getelementptr inbounds i8,i8*%bg,i64 16
%bq=bitcast i8*%bp to i8**
store i8*%bo,i8**%bq,align 8
%br=getelementptr inbounds i8,i8*%bg,i64 24
%bs=bitcast i8*%br to i32*
store i32 7,i32*%bs,align 4
%bt=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%bu=call fastcc i8*%aY(i8*inreg%bt,i8*inreg%bg)
store i8*%bu,i8**%c,align 8
%bv=call i8*@sml_alloc(i32 inreg 20)#0
%bw=getelementptr inbounds i8,i8*%bv,i64 -4
%bx=bitcast i8*%bw to i32*
store i32 1342177296,i32*%bx,align 4
%by=load i8*,i8**%d,align 8
%bz=bitcast i8*%bv to i8**
store i8*%by,i8**%bz,align 8
%bA=load i8*,i8**%c,align 8
%bB=getelementptr inbounds i8,i8*%bv,i64 8
%bC=bitcast i8*%bB to i8**
store i8*%bA,i8**%bC,align 8
%bD=getelementptr inbounds i8,i8*%bv,i64 16
%bE=bitcast i8*%bD to i32*
store i32 3,i32*%bE,align 4
ret i8*%bv
}
define internal fastcc i8*@_SMLLN11UserFileMap8fromListE_83(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%a,i8**%c,align 8
store i8*%b,i8**%d,align 8
%g=load atomic i32,i32*@sml_check_flag unordered,align 4
%h=icmp eq i32%g,0
br i1%h,label%i,label%k
i:
%j=bitcast i8*%a to i8**
br label%o
k:
call void@sml_check(i32 inreg%g)
%l=load i8*,i8**%d,align 8
%m=bitcast i8**%c to i8***
%n=load i8**,i8***%m,align 8
br label%o
o:
%p=phi i8**[%n,%k],[%j,%i]
%q=phi i8*[%l,%k],[%b,%i]
%r=bitcast i8*%q to i8**
%s=load i8*,i8**%r,align 8
%t=getelementptr inbounds i8,i8*%s,i64 8
%u=bitcast i8*%t to i8**
%v=load i8*,i8**%u,align 8
store i8*%v,i8**%d,align 8
%w=getelementptr inbounds i8,i8*%q,i64 8
%x=bitcast i8*%w to i8**
%y=load i8*,i8**%x,align 8
store i8*%y,i8**%e,align 8
store i8*null,i8**%c,align 8
%z=load i8*,i8**%p,align 8
store i8*%z,i8**%f,align 8
%A=bitcast i8*%q to i8***
%B=load i8**,i8***%A,align 8
%C=load i8*,i8**%B,align 8
%D=call fastcc i8*@_SMLFN8Filename10componentsE(i8*inreg%C)
store i8*%D,i8**%c,align 8
%E=call i8*@sml_alloc(i32 inreg 28)#0
%F=getelementptr inbounds i8,i8*%E,i64 -4
%G=bitcast i8*%F to i32*
store i32 1342177304,i32*%G,align 4
%H=load i8*,i8**%e,align 8
%I=bitcast i8*%E to i8**
store i8*%H,i8**%I,align 8
%J=load i8*,i8**%c,align 8
%K=getelementptr inbounds i8,i8*%E,i64 8
%L=bitcast i8*%K to i8**
store i8*%J,i8**%L,align 8
%M=load i8*,i8**%d,align 8
%N=getelementptr inbounds i8,i8*%E,i64 16
%O=bitcast i8*%N to i8**
store i8*%M,i8**%O,align 8
%P=getelementptr inbounds i8,i8*%E,i64 24
%Q=bitcast i8*%P to i32*
store i32 7,i32*%Q,align 4
%R=load i8*,i8**%f,align 8
%S=tail call fastcc i8*@_SMLLN11UserFileMap3addE_82(i8*inreg%R,i8*inreg%E)
ret i8*%S
}
define internal fastcc i8*@_SMLLN11UserFileMap8fromListE_84(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
br i1%i,label%k,label%j
j:
call void@sml_check(i32 inreg%h)
br label%k
k:
%l=call fastcc i8*@_SMLFN4List5foldlE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%m=getelementptr inbounds i8,i8*%l,i64 16
%n=bitcast i8*%m to i8*(i8*,i8*)**
%o=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%n,align 8
%p=bitcast i8*%l to i8**
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%f,align 8
%r=load i8*,i8**%d,align 8
%s=getelementptr inbounds i8,i8*%r,i64 8
%t=bitcast i8*%s to i8**
%u=load i8*,i8**%t,align 8
store i8*%u,i8**%e,align 8
%v=call i8*@sml_alloc(i32 inreg 12)#0
%w=getelementptr inbounds i8,i8*%v,i64 -4
%x=bitcast i8*%w to i32*
store i32 1342177288,i32*%x,align 4
store i8*%v,i8**%g,align 8
%y=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%z=bitcast i8*%v to i8**
store i8*%y,i8**%z,align 8
%A=getelementptr inbounds i8,i8*%v,i64 8
%B=bitcast i8*%A to i32*
store i32 1,i32*%B,align 4
%C=call i8*@sml_alloc(i32 inreg 28)#0
%D=getelementptr inbounds i8,i8*%C,i64 -4
%E=bitcast i8*%D to i32*
store i32 1342177304,i32*%E,align 4
%F=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%G=bitcast i8*%C to i8**
store i8*%F,i8**%G,align 8
%H=getelementptr inbounds i8,i8*%C,i64 8
%I=bitcast i8*%H to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11UserFileMap8fromListE_83 to void(...)*),void(...)**%I,align 8
%J=getelementptr inbounds i8,i8*%C,i64 16
%K=bitcast i8*%J to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11UserFileMap8fromListE_83 to void(...)*),void(...)**%K,align 8
%L=getelementptr inbounds i8,i8*%C,i64 24
%M=bitcast i8*%L to i32*
store i32 -2147483647,i32*%M,align 4
%N=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%O=call fastcc i8*%o(i8*inreg%N,i8*inreg%C)
%P=getelementptr inbounds i8,i8*%O,i64 16
%Q=bitcast i8*%P to i8*(i8*,i8*)**
%R=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%Q,align 8
%S=bitcast i8*%O to i8**
%T=load i8*,i8**%S,align 8
%U=bitcast i8**%d to i8***
%V=load i8**,i8***%U,align 8
store i8*null,i8**%d,align 8
%W=load i8*,i8**%V,align 8
%X=call fastcc i8*%R(i8*inreg%T,i8*inreg%W)
%Y=getelementptr inbounds i8,i8*%X,i64 16
%Z=bitcast i8*%Y to i8*(i8*,i8*)**
%aa=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%Z,align 8
%ab=bitcast i8*%X to i8**
%ac=load i8*,i8**%ab,align 8
%ad=load i8*,i8**%c,align 8
%ae=tail call fastcc i8*%aa(i8*inreg%ac,i8*inreg%ad)
ret i8*%ae
}
define internal fastcc i8*@_SMLLN11UserFileMap4getcE_88(i8*inreg%a)unnamed_addr#2 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
%d=bitcast i8*%a to i8**
%e=load i8*,i8**%d,align 8
store i8*%e,i8**%c,align 8
%f=getelementptr inbounds i8,i8*%a,i64 8
%g=bitcast i8*%f to i32*
%h=load i32,i32*%g,align 4
%i=getelementptr inbounds i8,i8*%e,i64 -4
%j=bitcast i8*%i to i32*
%k=load i32,i32*%j,align 4
%l=and i32%k,268435455
%m=add nsw i32%l,-1
%n=icmp sgt i32%m,%h
br i1%n,label%o,label%ao
o:
%p=icmp slt i32%h,0
br i1%p,label%W,label%q
q:
%r=sext i32%h to i64
%s=getelementptr inbounds i8,i8*%e,i64%r
%t=load i8,i8*%s,align 1
%u=add nsw i32%h,1
%v=call i8*@sml_alloc(i32 inreg 20)#0
%w=getelementptr inbounds i8,i8*%v,i64 -4
%x=bitcast i8*%w to i32*
store i32 1342177296,i32*%x,align 4
store i8*%v,i8**%b,align 8
%y=getelementptr inbounds i8,i8*%v,i64 12
%z=bitcast i8*%y to i32*
store i32 0,i32*%z,align 1
%A=bitcast i8*%v to i8**
%B=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
store i8*%B,i8**%A,align 8
%C=getelementptr inbounds i8,i8*%v,i64 8
%D=bitcast i8*%C to i32*
store i32%u,i32*%D,align 4
%E=getelementptr inbounds i8,i8*%v,i64 16
%F=bitcast i8*%E to i32*
store i32 1,i32*%F,align 4
%G=call i8*@sml_alloc(i32 inreg 20)#0
%H=getelementptr inbounds i8,i8*%G,i64 -4
%I=bitcast i8*%H to i32*
store i32 1342177296,i32*%I,align 4
store i8*%G,i8**%c,align 8
%J=getelementptr inbounds i8,i8*%G,i64 1
call void@llvm.memset.p0i8.i32(i8*%J,i8 0,i32 7,i1 false)
store i8%t,i8*%G,align 1
%K=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%L=getelementptr inbounds i8,i8*%G,i64 8
%M=bitcast i8*%L to i8**
store i8*%K,i8**%M,align 8
%N=getelementptr inbounds i8,i8*%G,i64 16
%O=bitcast i8*%N to i32*
store i32 2,i32*%O,align 4
%P=call i8*@sml_alloc(i32 inreg 12)#0
%Q=getelementptr inbounds i8,i8*%P,i64 -4
%R=bitcast i8*%Q to i32*
store i32 1342177288,i32*%R,align 4
%S=load i8*,i8**%c,align 8
%T=bitcast i8*%P to i8**
store i8*%S,i8**%T,align 8
%U=getelementptr inbounds i8,i8*%P,i64 8
%V=bitcast i8*%U to i32*
store i32 1,i32*%V,align 4
ret i8*%P
W:
store i8*null,i8**%c,align 8
%X=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%X,i8**%b,align 8
%Y=call i8*@sml_alloc(i32 inreg 20)#0
%Z=getelementptr inbounds i8,i8*%Y,i64 -4
%aa=bitcast i8*%Z to i32*
store i32 1342177296,i32*%aa,align 4
store i8*%Y,i8**%c,align 8
%ab=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%ac=bitcast i8*%Y to i8**
store i8*%ab,i8**%ac,align 8
%ad=getelementptr inbounds i8,i8*%Y,i64 8
%ae=bitcast i8*%ad to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[65x i8]}>,<{[4x i8],i32,[65x i8]}>*@c,i64 0,i32 2,i64 0),i8**%ae,align 8
%af=getelementptr inbounds i8,i8*%Y,i64 16
%ag=bitcast i8*%af to i32*
store i32 3,i32*%ag,align 4
%ah=call i8*@sml_alloc(i32 inreg 60)#0
%ai=getelementptr inbounds i8,i8*%ah,i64 -4
%aj=bitcast i8*%ai to i32*
store i32 1342177336,i32*%aj,align 4
%ak=getelementptr inbounds i8,i8*%ah,i64 56
%al=bitcast i8*%ak to i32*
store i32 1,i32*%al,align 4
%am=load i8*,i8**%c,align 8
%an=bitcast i8*%ah to i8**
store i8*%am,i8**%an,align 8
call void@sml_raise(i8*inreg%ah)#1
unreachable
ao:
ret i8*null
}
define internal fastcc i8*@_SMLLN11UserFileMap4spanE_90(i8*inreg%a)unnamed_addr#2 gc"smlsharp"{
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
%j=bitcast i8*%h to i8**
%k=bitcast i8*%h to i8***
%l=load i8**,i8***%k,align 8
%m=load i8*,i8**%l,align 8
store i8*%m,i8**%b,align 8
%n=load i8*,i8**%j,align 8
%o=getelementptr inbounds i8,i8*%n,i64 8
%p=bitcast i8*%o to i32*
%q=load i32,i32*%p,align 4
%r=getelementptr inbounds i8,i8*%h,i64 8
%s=bitcast i8*%r to i8**
%t=load i8*,i8**%s,align 8
%u=getelementptr inbounds i8,i8*%t,i64 8
%v=bitcast i8*%u to i32*
%w=load i32,i32*%v,align 4
%x=sub nsw i32%w,%q
%y=call i8*@sml_alloc(i32 inreg 20)#0
%z=getelementptr inbounds i8,i8*%y,i64 -4
%A=bitcast i8*%z to i32*
store i32 1342177296,i32*%A,align 4
%B=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%C=bitcast i8*%y to i8**
store i8*%B,i8**%C,align 8
%D=getelementptr inbounds i8,i8*%y,i64 8
%E=bitcast i8*%D to i32*
store i32%q,i32*%E,align 4
%F=getelementptr inbounds i8,i8*%y,i64 12
%G=bitcast i8*%F to i32*
store i32%x,i32*%G,align 4
%H=getelementptr inbounds i8,i8*%y,i64 16
%I=bitcast i8*%H to i32*
store i32 1,i32*%I,align 4
%J=call fastcc i8*@_SMLFN6String9substringE(i8*inreg%y)
%K=tail call fastcc i8*@_SMLFN8Filename10fromStringE(i8*inreg%J)
ret i8*%K
}
define internal fastcc i8*@_SMLLN11UserFileMap6striplE_92(i8*inreg%a)unnamed_addr#2 gc"smlsharp"{
f:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
br label%d
d:
%e=phi i8*[%Z,%X],[%a,%f]
store i8*%e,i8**%b,align 8
%g=load atomic i32,i32*@sml_check_flag unordered,align 4
%h=icmp eq i32%g,0
br i1%h,label%k,label%i
i:
call void@sml_check(i32 inreg%g)
%j=load i8*,i8**%b,align 8
br label%k
k:
%l=phi i8*[%j,%i],[%e,%d]
%m=bitcast i8*%l to i8**
%n=load i8*,i8**%m,align 8
store i8*%n,i8**%b,align 8
%o=getelementptr inbounds i8,i8*%l,i64 8
%p=bitcast i8*%o to i32*
%q=load i32,i32*%p,align 4
%r=getelementptr inbounds i8,i8*%n,i64 -4
%s=bitcast i8*%r to i32*
%t=load i32,i32*%s,align 4
%u=and i32%t,268435455
%v=add nsw i32%u,-1
%w=icmp sgt i32%v,%q
br i1%w,label%x,label%ak
x:
%y=icmp sgt i32%q,-1
br i1%y,label%R,label%z
z:
%A=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%A,i8**%b,align 8
%B=call i8*@sml_alloc(i32 inreg 20)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177296,i32*%D,align 4
store i8*%B,i8**%c,align 8
%E=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%F=bitcast i8*%B to i8**
store i8*%E,i8**%F,align 8
%G=getelementptr inbounds i8,i8*%B,i64 8
%H=bitcast i8*%G to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[65x i8]}>,<{[4x i8],i32,[65x i8]}>*@d,i64 0,i32 2,i64 0),i8**%H,align 8
%I=getelementptr inbounds i8,i8*%B,i64 16
%J=bitcast i8*%I to i32*
store i32 3,i32*%J,align 4
%K=call i8*@sml_alloc(i32 inreg 60)#0
%L=getelementptr inbounds i8,i8*%K,i64 -4
%M=bitcast i8*%L to i32*
store i32 1342177336,i32*%M,align 4
%N=getelementptr inbounds i8,i8*%K,i64 56
%O=bitcast i8*%N to i32*
store i32 1,i32*%O,align 4
%P=load i8*,i8**%c,align 8
%Q=bitcast i8*%K to i8**
store i8*%P,i8**%Q,align 8
call void@sml_raise(i8*inreg%K)#1
unreachable
R:
%S=sext i32%q to i64
%T=getelementptr inbounds i8,i8*%n,i64%S
%U=load i8,i8*%T,align 1
%V=call fastcc i32@_SMLFN4Char7isSpaceE(i8 inreg%U)
%W=icmp eq i32%V,0
br i1%W,label%ak,label%X
X:
%Y=add nsw i32%q,1
%Z=call i8*@sml_alloc(i32 inreg 20)#0
%aa=getelementptr inbounds i8,i8*%Z,i64 -4
%ab=bitcast i8*%aa to i32*
store i32 1342177296,i32*%ab,align 4
%ac=getelementptr inbounds i8,i8*%Z,i64 12
%ad=bitcast i8*%ac to i32*
store i32 0,i32*%ad,align 1
%ae=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%af=bitcast i8*%Z to i8**
store i8*%ae,i8**%af,align 8
%ag=getelementptr inbounds i8,i8*%Z,i64 8
%ah=bitcast i8*%ag to i32*
store i32%Y,i32*%ah,align 4
%ai=getelementptr inbounds i8,i8*%Z,i64 16
%aj=bitcast i8*%ai to i32*
store i32 1,i32*%aj,align 4
br label%d
ak:
%al=call i8*@sml_alloc(i32 inreg 20)#0
%am=getelementptr inbounds i8,i8*%al,i64 -4
%an=bitcast i8*%am to i32*
store i32 1342177296,i32*%an,align 4
%ao=getelementptr inbounds i8,i8*%al,i64 12
%ap=bitcast i8*%ao to i32*
store i32 0,i32*%ap,align 1
%aq=load i8*,i8**%b,align 8
%ar=bitcast i8*%al to i8**
store i8*%aq,i8**%ar,align 8
%as=getelementptr inbounds i8,i8*%al,i64 8
%at=bitcast i8*%as to i32*
store i32%q,i32*%at,align 4
%au=getelementptr inbounds i8,i8*%al,i64 16
%av=bitcast i8*%au to i32*
store i32 1,i32*%av,align 4
ret i8*%al
}
define internal fastcc i8*@_SMLLN11UserFileMap6splitlE_100(i8 inreg%a,i8*inreg%b)unnamed_addr#2 gc"smlsharp"{
h:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
br label%f
f:
%g=phi i8*[%ac,%a8],[%b,%h]
store i8*%g,i8**%c,align 8
%i=load atomic i32,i32*@sml_check_flag unordered,align 4
%j=icmp eq i32%i,0
br i1%j,label%m,label%k
k:
call void@sml_check(i32 inreg%i)
%l=load i8*,i8**%c,align 8
br label%m
m:
%n=phi i8*[%l,%k],[%g,%f]
%o=bitcast i8*%n to i8**
%p=load i8*,i8**%o,align 8
store i8*%p,i8**%d,align 8
%q=getelementptr inbounds i8,i8*%n,i64 8
%r=bitcast i8*%q to i32*
%s=load i32,i32*%r,align 4
%t=getelementptr inbounds i8,i8*%p,i64 -4
%u=bitcast i8*%t to i32*
%v=load i32,i32*%u,align 4
%w=and i32%v,268435455
%x=add nsw i32%w,-1
%y=icmp sgt i32%x,%s
br i1%y,label%U,label%z
z:
%A=call i8*@sml_alloc(i32 inreg 20)#0
%B=getelementptr inbounds i8,i8*%A,i64 -4
%C=bitcast i8*%B to i32*
store i32 1342177296,i32*%C,align 4
store i8*%A,i8**%c,align 8
%D=getelementptr inbounds i8,i8*%A,i64 12
%E=bitcast i8*%D to i32*
store i32 0,i32*%E,align 1
%F=bitcast i8*%A to i8**
%G=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
store i8*%G,i8**%F,align 8
%H=getelementptr inbounds i8,i8*%A,i64 8
%I=bitcast i8*%H to i32*
store i32%s,i32*%I,align 4
%J=getelementptr inbounds i8,i8*%A,i64 16
%K=bitcast i8*%J to i32*
store i32 1,i32*%K,align 4
%L=call i8*@sml_alloc(i32 inreg 20)#0
%M=getelementptr inbounds i8,i8*%L,i64 -4
%N=bitcast i8*%M to i32*
store i32 1342177296,i32*%N,align 4
%O=load i8*,i8**%c,align 8
%P=bitcast i8*%L to i8**
store i8*%O,i8**%P,align 8
%Q=getelementptr inbounds i8,i8*%L,i64 8
%R=bitcast i8*%Q to i8**
store i8*null,i8**%R,align 8
%S=getelementptr inbounds i8,i8*%L,i64 16
%T=bitcast i8*%S to i32*
store i32 3,i32*%T,align 4
ret i8*%L
U:
%V=icmp slt i32%s,0
br i1%V,label%af,label%W
W:
%X=sext i32%s to i64
%Y=getelementptr inbounds i8,i8*%p,i64%X
%Z=load i8,i8*%Y,align 1
%aa=icmp eq i8%Z,%a
%ab=add nsw i32%s,1
%ac=call i8*@sml_alloc(i32 inreg 20)#0
%ad=getelementptr inbounds i8,i8*%ac,i64 -4
%ae=bitcast i8*%ad to i32*
store i32 1342177296,i32*%ae,align 4
br i1%aa,label%ax,label%a8
af:
store i8*null,i8**%d,align 8
%ag=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%ag,i8**%c,align 8
%ah=call i8*@sml_alloc(i32 inreg 20)#0
%ai=getelementptr inbounds i8,i8*%ah,i64 -4
%aj=bitcast i8*%ai to i32*
store i32 1342177296,i32*%aj,align 4
store i8*%ah,i8**%d,align 8
%ak=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%al=bitcast i8*%ah to i8**
store i8*%ak,i8**%al,align 8
%am=getelementptr inbounds i8,i8*%ah,i64 8
%an=bitcast i8*%am to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[65x i8]}>,<{[4x i8],i32,[65x i8]}>*@f,i64 0,i32 2,i64 0),i8**%an,align 8
%ao=getelementptr inbounds i8,i8*%ah,i64 16
%ap=bitcast i8*%ao to i32*
store i32 3,i32*%ap,align 4
%aq=call i8*@sml_alloc(i32 inreg 60)#0
%ar=getelementptr inbounds i8,i8*%aq,i64 -4
%as=bitcast i8*%ar to i32*
store i32 1342177336,i32*%as,align 4
%at=getelementptr inbounds i8,i8*%aq,i64 56
%au=bitcast i8*%at to i32*
store i32 1,i32*%au,align 4
%av=load i8*,i8**%d,align 8
%aw=bitcast i8*%aq to i8**
store i8*%av,i8**%aw,align 8
call void@sml_raise(i8*inreg%aq)#1
unreachable
ax:
store i8*%ac,i8**%c,align 8
%ay=getelementptr inbounds i8,i8*%ac,i64 12
%az=bitcast i8*%ay to i32*
store i32 0,i32*%az,align 1
%aA=load i8*,i8**%d,align 8
%aB=bitcast i8*%ac to i8**
store i8*%aA,i8**%aB,align 8
%aC=getelementptr inbounds i8,i8*%ac,i64 8
%aD=bitcast i8*%aC to i32*
store i32%ab,i32*%aD,align 4
%aE=getelementptr inbounds i8,i8*%ac,i64 16
%aF=bitcast i8*%aE to i32*
store i32 1,i32*%aF,align 4
%aG=call i8*@sml_alloc(i32 inreg 12)#0
%aH=getelementptr inbounds i8,i8*%aG,i64 -4
%aI=bitcast i8*%aH to i32*
store i32 1342177288,i32*%aI,align 4
store i8*%aG,i8**%e,align 8
%aJ=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aK=bitcast i8*%aG to i8**
store i8*%aJ,i8**%aK,align 8
%aL=getelementptr inbounds i8,i8*%aG,i64 8
%aM=bitcast i8*%aL to i32*
store i32 1,i32*%aM,align 4
%aN=call i8*@sml_alloc(i32 inreg 20)#0
%aO=getelementptr inbounds i8,i8*%aN,i64 -4
%aP=bitcast i8*%aO to i32*
store i32 1342177296,i32*%aP,align 4
store i8*%aN,i8**%c,align 8
%aQ=getelementptr inbounds i8,i8*%aN,i64 12
%aR=bitcast i8*%aQ to i32*
store i32 0,i32*%aR,align 1
%aS=load i8*,i8**%d,align 8
%aT=bitcast i8*%aN to i8**
store i8*null,i8**%d,align 8
store i8*%aS,i8**%aT,align 8
%aU=getelementptr inbounds i8,i8*%aN,i64 8
%aV=bitcast i8*%aU to i32*
store i32%s,i32*%aV,align 4
%aW=getelementptr inbounds i8,i8*%aN,i64 16
%aX=bitcast i8*%aW to i32*
store i32 1,i32*%aX,align 4
%aY=call i8*@sml_alloc(i32 inreg 20)#0
%aZ=getelementptr inbounds i8,i8*%aY,i64 -4
%a0=bitcast i8*%aZ to i32*
store i32 1342177296,i32*%a0,align 4
%a1=load i8*,i8**%c,align 8
%a2=bitcast i8*%aY to i8**
store i8*%a1,i8**%a2,align 8
%a3=load i8*,i8**%e,align 8
%a4=getelementptr inbounds i8,i8*%aY,i64 8
%a5=bitcast i8*%a4 to i8**
store i8*%a3,i8**%a5,align 8
%a6=getelementptr inbounds i8,i8*%aY,i64 16
%a7=bitcast i8*%a6 to i32*
store i32 3,i32*%a7,align 4
ret i8*%aY
a8:
%a9=getelementptr inbounds i8,i8*%ac,i64 12
%ba=bitcast i8*%a9 to i32*
store i32 0,i32*%ba,align 1
%bb=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bc=bitcast i8*%ac to i8**
store i8*%bb,i8**%bc,align 8
%bd=getelementptr inbounds i8,i8*%ac,i64 8
%be=bitcast i8*%bd to i32*
store i32%ab,i32*%be,align 4
%bf=getelementptr inbounds i8,i8*%ac,i64 16
%bg=bitcast i8*%bf to i32*
store i32 1,i32*%bg,align 4
br label%f
}
define internal fastcc i8*@_SMLLN11UserFileMap9parseLineE_112(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
q:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
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
store i8*%a,i8**%j,align 8
store i8*%b,i8**%e,align 8
%k=load atomic i32,i32*@sml_check_flag unordered,align 4
%l=icmp eq i32%k,0
br i1%l,label%o,label%m
m:
call void@sml_check(i32 inreg%k)
%n=load i8*,i8**%e,align 8
br label%o
o:
%p=phi i8*[%n,%m],[%b,%q]
store i8*null,i8**%e,align 8
%r=call fastcc i8*@_SMLLN11UserFileMap6striplE_92(i8*inreg%p)
%s=call fastcc i8*@_SMLLN11UserFileMap4getcE_88(i8*inreg%r)
%t=icmp eq i8*%s,null
br i1%t,label%u,label%v
u:
ret i8*null
v:
%w=bitcast i8*%s to i8**
%x=load i8*,i8**%w,align 8
%y=load i8,i8*%x,align 1
switch i8%y,label%z[
i8 35,label%u
i8 61,label%aC
]
z:
%A=call fastcc i8*@_SMLFN6String3strE(i8 inreg%y)
store i8*%A,i8**%e,align 8
%B=call i8*@sml_alloc(i32 inreg 20)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177296,i32*%D,align 4
%E=bitcast i8*%B to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[22x i8]}>,<{[4x i8],i32,[22x i8]}>*@i,i64 0,i32 2,i64 0),i8**%E,align 8
%F=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%G=getelementptr inbounds i8,i8*%B,i64 8
%H=bitcast i8*%G to i8**
store i8*%F,i8**%H,align 8
%I=getelementptr inbounds i8,i8*%B,i64 16
%J=bitcast i8*%I to i32*
store i32 3,i32*%J,align 4
%K=call fastcc i8*@_SMLFN6String1_ZE(i8*inreg%B)
store i8*%K,i8**%e,align 8
%L=bitcast i8**%j to i32**
%M=load i32*,i32**%L,align 8
store i8*null,i8**%j,align 8
%N=load i32,i32*%M,align 4
%O=call i8*@sml_alloc(i32 inreg 20)#0
%P=bitcast i8*%O to i32*
%Q=getelementptr inbounds i8,i8*%O,i64 -4
%R=bitcast i8*%Q to i32*
store i32 1342177296,i32*%R,align 4
%S=getelementptr inbounds i8,i8*%O,i64 4
%T=bitcast i8*%S to i32*
store i32 0,i32*%T,align 1
store i32%N,i32*%P,align 4
%U=load i8*,i8**%e,align 8
%V=getelementptr inbounds i8,i8*%O,i64 8
%W=bitcast i8*%V to i8**
store i8*%U,i8**%W,align 8
%X=getelementptr inbounds i8,i8*%O,i64 16
%Y=bitcast i8*%X to i32*
store i32 2,i32*%Y,align 4
%Z=call i8*@sml_alloc(i32 inreg 20)#0
%aa=getelementptr inbounds i8,i8*%Z,i64 -4
%ab=bitcast i8*%aa to i32*
store i32 1342177296,i32*%ab,align 4
store i8*%Z,i8**%f,align 8
%ac=getelementptr inbounds i8,i8*%Z,i64 4
%ad=bitcast i8*%ac to i32*
store i32 0,i32*%ad,align 1
%ae=bitcast i8*%Z to i32*
store i32%N,i32*%ae,align 4
%af=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ag=getelementptr inbounds i8,i8*%Z,i64 8
%ah=bitcast i8*%ag to i8**
store i8*%af,i8**%ah,align 8
%ai=getelementptr inbounds i8,i8*%Z,i64 16
%aj=bitcast i8*%ai to i32*
store i32 2,i32*%aj,align 4
%ak=call i8*@sml_alloc(i32 inreg 28)#0
%al=getelementptr inbounds i8,i8*%ak,i64 -4
%am=bitcast i8*%al to i32*
store i32 1342177304,i32*%am,align 4
store i8*%ak,i8**%e,align 8
%an=bitcast i8*%ak to i8**
store i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL81,i64 0,i32 2)to i8*),i8**%an,align 8
%ao=getelementptr inbounds i8,i8*%ak,i64 8
%ap=bitcast i8*%ao to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[64x i8]}>,<{[4x i8],i32,[64x i8]}>*@j,i64 0,i32 2,i64 0),i8**%ap,align 8
%aq=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ar=getelementptr inbounds i8,i8*%ak,i64 16
%as=bitcast i8*%ar to i8**
store i8*%aq,i8**%as,align 8
%at=getelementptr inbounds i8,i8*%ak,i64 24
%au=bitcast i8*%at to i32*
store i32 7,i32*%au,align 4
%av=call i8*@sml_alloc(i32 inreg 60)#0
%aw=getelementptr inbounds i8,i8*%av,i64 -4
%ax=bitcast i8*%aw to i32*
store i32 1342177336,i32*%ax,align 4
%ay=getelementptr inbounds i8,i8*%av,i64 56
%az=bitcast i8*%ay to i32*
store i32 1,i32*%az,align 4
%aA=load i8*,i8**%e,align 8
%aB=bitcast i8*%av to i8**
store i8*%aA,i8**%aB,align 8
call void@sml_raise(i8*inreg%av)#1
unreachable
aC:
%aD=getelementptr inbounds i8,i8*%x,i64 8
%aE=bitcast i8*%aD to i8**
%aF=load i8*,i8**%aE,align 8
%aG=call fastcc i8*@_SMLLN11UserFileMap4getcE_88(i8*inreg%aF)
%aH=icmp eq i8*%aG,null
br i1%aH,label%aI,label%be
aI:
%aJ=bitcast i8**%j to i32**
%aK=load i32*,i32**%aJ,align 8
store i8*null,i8**%j,align 8
%aL=load i32,i32*%aK,align 4
%aM=call i8*@sml_alloc(i32 inreg 20)#0
%aN=getelementptr inbounds i8,i8*%aM,i64 -4
%aO=bitcast i8*%aN to i32*
store i32 1342177296,i32*%aO,align 4
store i8*%aM,i8**%e,align 8
%aP=getelementptr inbounds i8,i8*%aM,i64 4
%aQ=bitcast i8*%aP to i32*
store i32 0,i32*%aQ,align 1
%aR=bitcast i8*%aM to i32*
store i32%aL,i32*%aR,align 4
%aS=getelementptr inbounds i8,i8*%aM,i64 8
%aT=bitcast i8*%aS to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[23x i8]}>,<{[4x i8],i32,[23x i8]}>*@h,i64 0,i32 2,i64 0),i8**%aT,align 8
%aU=getelementptr inbounds i8,i8*%aM,i64 16
%aV=bitcast i8*%aU to i32*
store i32 2,i32*%aV,align 4
%aW=call i8*@sml_alloc(i32 inreg 28)#0
%aX=getelementptr inbounds i8,i8*%aW,i64 -4
%aY=bitcast i8*%aX to i32*
store i32 1342177304,i32*%aY,align 4
store i8*%aW,i8**%f,align 8
%aZ=bitcast i8*%aW to i8**
store i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL81,i64 0,i32 2)to i8*),i8**%aZ,align 8
%a0=getelementptr inbounds i8,i8*%aW,i64 8
%a1=bitcast i8*%a0 to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[64x i8]}>,<{[4x i8],i32,[64x i8]}>*@j,i64 0,i32 2,i64 0),i8**%a1,align 8
%a2=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%a3=getelementptr inbounds i8,i8*%aW,i64 16
%a4=bitcast i8*%a3 to i8**
store i8*%a2,i8**%a4,align 8
%a5=getelementptr inbounds i8,i8*%aW,i64 24
%a6=bitcast i8*%a5 to i32*
store i32 7,i32*%a6,align 4
%a7=call i8*@sml_alloc(i32 inreg 60)#0
%a8=getelementptr inbounds i8,i8*%a7,i64 -4
%a9=bitcast i8*%a8 to i32*
store i32 1342177336,i32*%a9,align 4
%ba=getelementptr inbounds i8,i8*%a7,i64 56
%bb=bitcast i8*%ba to i32*
store i32 1,i32*%bb,align 4
%bc=load i8*,i8**%f,align 8
%bd=bitcast i8*%a7 to i8**
store i8*%bc,i8**%bd,align 8
call void@sml_raise(i8*inreg%a7)#1
unreachable
be:
%bf=bitcast i8*%aG to i8**
%bg=load i8*,i8**%bf,align 8
store i8*%bg,i8**%e,align 8
%bh=getelementptr inbounds i8,i8*%bg,i64 8
%bi=bitcast i8*%bh to i8**
%bj=load i8*,i8**%bi,align 8
store i8*%bj,i8**%f,align 8
%bk=load i8,i8*%bg,align 1
%bl=call fastcc i8*@_SMLLN11UserFileMap6splitlE_100(i8 inreg%bk,i8*inreg%bj)
%bm=bitcast i8*%bl to i8**
%bn=load i8*,i8**%bm,align 8
store i8*%bn,i8**%g,align 8
%bo=getelementptr inbounds i8,i8*%bl,i64 8
%bp=bitcast i8*%bo to i8**
%bq=load i8*,i8**%bp,align 8
%br=icmp eq i8*%bq,null
br i1%br,label%bs,label%bY
bs:
store i8*null,i8**%e,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%g,align 8
%bt=bitcast i8**%j to i32**
%bu=load i32*,i32**%bt,align 8
store i8*null,i8**%j,align 8
%bv=load i32,i32*%bu,align 4
%bw=call i8*@sml_alloc(i32 inreg 20)#0
%bx=getelementptr inbounds i8,i8*%bw,i64 -4
%by=bitcast i8*%bx to i32*
store i32 1342177296,i32*%by,align 4
store i8*%bw,i8**%e,align 8
%bz=getelementptr inbounds i8,i8*%bw,i64 4
%bA=bitcast i8*%bz to i32*
store i32 0,i32*%bA,align 1
%bB=bitcast i8*%bw to i32*
store i32%bv,i32*%bB,align 4
%bC=getelementptr inbounds i8,i8*%bw,i64 8
%bD=bitcast i8*%bC to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[23x i8]}>,<{[4x i8],i32,[23x i8]}>*@h,i64 0,i32 2,i64 0),i8**%bD,align 8
%bE=getelementptr inbounds i8,i8*%bw,i64 16
%bF=bitcast i8*%bE to i32*
store i32 2,i32*%bF,align 4
%bG=call i8*@sml_alloc(i32 inreg 28)#0
%bH=getelementptr inbounds i8,i8*%bG,i64 -4
%bI=bitcast i8*%bH to i32*
store i32 1342177304,i32*%bI,align 4
store i8*%bG,i8**%f,align 8
%bJ=bitcast i8*%bG to i8**
store i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL81,i64 0,i32 2)to i8*),i8**%bJ,align 8
%bK=getelementptr inbounds i8,i8*%bG,i64 8
%bL=bitcast i8*%bK to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[64x i8]}>,<{[4x i8],i32,[64x i8]}>*@j,i64 0,i32 2,i64 0),i8**%bL,align 8
%bM=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bN=getelementptr inbounds i8,i8*%bG,i64 16
%bO=bitcast i8*%bN to i8**
store i8*%bM,i8**%bO,align 8
%bP=getelementptr inbounds i8,i8*%bG,i64 24
%bQ=bitcast i8*%bP to i32*
store i32 7,i32*%bQ,align 4
%bR=call i8*@sml_alloc(i32 inreg 60)#0
%bS=getelementptr inbounds i8,i8*%bR,i64 -4
%bT=bitcast i8*%bS to i32*
store i32 1342177336,i32*%bT,align 4
%bU=getelementptr inbounds i8,i8*%bR,i64 56
%bV=bitcast i8*%bU to i32*
store i32 1,i32*%bV,align 4
%bW=load i8*,i8**%f,align 8
%bX=bitcast i8*%bR to i8**
store i8*%bW,i8**%bX,align 8
call void@sml_raise(i8*inreg%bR)#1
unreachable
bY:
%bZ=bitcast i8*%bq to i8**
%b0=load i8*,i8**%bZ,align 8
store i8*%b0,i8**%h,align 8
%b1=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%b2=load i8,i8*%b1,align 1
%b3=call fastcc i8*@_SMLLN11UserFileMap6splitlE_100(i8 inreg%b2,i8*inreg%b0)
%b4=bitcast i8*%b3 to i8**
%b5=load i8*,i8**%b4,align 8
store i8*%b5,i8**%i,align 8
%b6=getelementptr inbounds i8,i8*%b3,i64 8
%b7=bitcast i8*%b6 to i8**
%b8=load i8*,i8**%b7,align 8
%b9=icmp eq i8*%b8,null
br i1%b9,label%ca,label%dY
ca:
store i8*null,i8**%j,align 8
%cb=call i8*@sml_alloc(i32 inreg 20)#0
%cc=getelementptr inbounds i8,i8*%cb,i64 -4
%cd=bitcast i8*%cc to i32*
store i32 1342177296,i32*%cd,align 4
%ce=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%cf=bitcast i8*%cb to i8**
store i8*%ce,i8**%cf,align 8
%cg=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%ch=getelementptr inbounds i8,i8*%cb,i64 8
%ci=bitcast i8*%ch to i8**
store i8*%cg,i8**%ci,align 8
%cj=getelementptr inbounds i8,i8*%cb,i64 16
%ck=bitcast i8*%cj to i32*
store i32 3,i32*%ck,align 4
%cl=call fastcc i8*@_SMLLN11UserFileMap4spanE_90(i8*inreg%cb)
store i8*%cl,i8**%f,align 8
%cm=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%cn=bitcast i8**%c to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%cn)
%co=bitcast i8**%d to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%co)
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
br label%cp
cp:
%cq=phi i8*[%c9,%c8],[%cm,%ca]
store i8*%cq,i8**%c,align 8
%cr=load atomic i32,i32*@sml_check_flag unordered,align 4
%cs=icmp eq i32%cr,0
br i1%cs,label%cv,label%ct
ct:
call void@sml_check(i32 inreg%cr)
%cu=load i8*,i8**%c,align 8
br label%cv
cv:
%cw=phi i8*[%cu,%ct],[%cq,%cp]
%cx=bitcast i8*%cw to i8**
%cy=load i8*,i8**%cx,align 8
store i8*%cy,i8**%c,align 8
%cz=getelementptr inbounds i8,i8*%cw,i64 8
%cA=bitcast i8*%cz to i32*
%cB=load i32,i32*%cA,align 4
%cC=icmp slt i32%cB,1
br i1%cC,label%dk,label%cD
cD:
%cE=getelementptr inbounds i8,i8*%cy,i64 -4
%cF=bitcast i8*%cE to i32*
%cG=load i32,i32*%cF,align 4
%cH=and i32%cG,268435455
%cI=icmp slt i32%cB,%cH
br i1%cI,label%c1,label%cJ
cJ:
%cK=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%cK,i8**%c,align 8
%cL=call i8*@sml_alloc(i32 inreg 20)#0
%cM=getelementptr inbounds i8,i8*%cL,i64 -4
%cN=bitcast i8*%cM to i32*
store i32 1342177296,i32*%cN,align 4
store i8*%cL,i8**%d,align 8
%cO=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%cP=bitcast i8*%cL to i8**
store i8*%cO,i8**%cP,align 8
%cQ=getelementptr inbounds i8,i8*%cL,i64 8
%cR=bitcast i8*%cQ to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[65x i8]}>,<{[4x i8],i32,[65x i8]}>*@e,i64 0,i32 2,i64 0),i8**%cR,align 8
%cS=getelementptr inbounds i8,i8*%cL,i64 16
%cT=bitcast i8*%cS to i32*
store i32 3,i32*%cT,align 4
%cU=call i8*@sml_alloc(i32 inreg 60)#0
%cV=getelementptr inbounds i8,i8*%cU,i64 -4
%cW=bitcast i8*%cV to i32*
store i32 1342177336,i32*%cW,align 4
%cX=getelementptr inbounds i8,i8*%cU,i64 56
%cY=bitcast i8*%cX to i32*
store i32 1,i32*%cY,align 4
%cZ=load i8*,i8**%d,align 8
%c0=bitcast i8*%cU to i8**
store i8*%cZ,i8**%c0,align 8
call void@sml_raise(i8*inreg%cU)#1
unreachable
c1:
%c2=add nsw i32%cB,-1
%c3=sext i32%c2 to i64
%c4=getelementptr inbounds i8,i8*%cy,i64%c3
%c5=load i8,i8*%c4,align 1
%c6=call fastcc i32@_SMLFN4Char7isSpaceE(i8 inreg%c5)
%c7=icmp eq i32%c6,0
br i1%c7,label%dk,label%c8
c8:
%c9=call i8*@sml_alloc(i32 inreg 20)#0
%da=getelementptr inbounds i8,i8*%c9,i64 -4
%db=bitcast i8*%da to i32*
store i32 1342177296,i32*%db,align 4
%dc=getelementptr inbounds i8,i8*%c9,i64 12
%dd=bitcast i8*%dc to i32*
store i32 0,i32*%dd,align 1
%de=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%df=bitcast i8*%c9 to i8**
store i8*%de,i8**%df,align 8
%dg=getelementptr inbounds i8,i8*%c9,i64 8
%dh=bitcast i8*%dg to i32*
store i32%c2,i32*%dh,align 4
%di=getelementptr inbounds i8,i8*%c9,i64 16
%dj=bitcast i8*%di to i32*
store i32 1,i32*%dj,align 4
br label%cp
dk:
%dl=call i8*@sml_alloc(i32 inreg 20)#0
%dm=getelementptr inbounds i8,i8*%dl,i64 -4
%dn=bitcast i8*%dm to i32*
store i32 1342177296,i32*%dn,align 4
%do=getelementptr inbounds i8,i8*%dl,i64 12
%dp=bitcast i8*%do to i32*
store i32 0,i32*%dp,align 1
%dq=load i8*,i8**%c,align 8
%dr=bitcast i8*%dl to i8**
store i8*%dq,i8**%dr,align 8
%ds=getelementptr inbounds i8,i8*%dl,i64 8
%dt=bitcast i8*%ds to i32*
store i32%cB,i32*%dt,align 4
%du=getelementptr inbounds i8,i8*%dl,i64 16
%dv=bitcast i8*%du to i32*
store i32 1,i32*%dv,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%cn)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%co)
store i8*%dl,i8**%e,align 8
%dw=call i8*@sml_alloc(i32 inreg 20)#0
%dx=getelementptr inbounds i8,i8*%dw,i64 -4
%dy=bitcast i8*%dx to i32*
store i32 1342177296,i32*%dy,align 4
%dz=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%dA=bitcast i8*%dw to i8**
store i8*%dz,i8**%dA,align 8
%dB=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%dC=getelementptr inbounds i8,i8*%dw,i64 8
%dD=bitcast i8*%dC to i8**
store i8*%dB,i8**%dD,align 8
%dE=getelementptr inbounds i8,i8*%dw,i64 16
%dF=bitcast i8*%dE to i32*
store i32 3,i32*%dF,align 4
%dG=call fastcc i8*@_SMLLN11UserFileMap4spanE_90(i8*inreg%dw)
store i8*%dG,i8**%e,align 8
%dH=call i8*@sml_alloc(i32 inreg 20)#0
%dI=getelementptr inbounds i8,i8*%dH,i64 -4
%dJ=bitcast i8*%dI to i32*
store i32 1342177296,i32*%dJ,align 4
store i8*%dH,i8**%g,align 8
%dK=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%dL=bitcast i8*%dH to i8**
store i8*%dK,i8**%dL,align 8
%dM=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%dN=getelementptr inbounds i8,i8*%dH,i64 8
%dO=bitcast i8*%dN to i8**
store i8*%dM,i8**%dO,align 8
%dP=getelementptr inbounds i8,i8*%dH,i64 16
%dQ=bitcast i8*%dP to i32*
store i32 3,i32*%dQ,align 4
%dR=call i8*@sml_alloc(i32 inreg 12)#0
%dS=getelementptr inbounds i8,i8*%dR,i64 -4
%dT=bitcast i8*%dS to i32*
store i32 1342177288,i32*%dT,align 4
%dU=load i8*,i8**%g,align 8
%dV=bitcast i8*%dR to i8**
store i8*%dU,i8**%dV,align 8
%dW=getelementptr inbounds i8,i8*%dR,i64 8
%dX=bitcast i8*%dW to i32*
store i32 1,i32*%dX,align 4
ret i8*%dR
dY:
%dZ=bitcast i8*%b8 to i8**
%d0=load i8*,i8**%dZ,align 8
%d1=call fastcc i8*@_SMLLN11UserFileMap6striplE_92(i8*inreg%d0)
%d2=call fastcc i8*@_SMLLN11UserFileMap4getcE_88(i8*inreg%d1)
%d3=icmp eq i8*%d2,null
br i1%d3,label%d4,label%eI
d4:
store i8*null,i8**%j,align 8
%d5=call i8*@sml_alloc(i32 inreg 20)#0
%d6=getelementptr inbounds i8,i8*%d5,i64 -4
%d7=bitcast i8*%d6 to i32*
store i32 1342177296,i32*%d7,align 4
%d8=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%d9=bitcast i8*%d5 to i8**
store i8*%d8,i8**%d9,align 8
%ea=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%eb=getelementptr inbounds i8,i8*%d5,i64 8
%ec=bitcast i8*%eb to i8**
store i8*%ea,i8**%ec,align 8
%ed=getelementptr inbounds i8,i8*%d5,i64 16
%ee=bitcast i8*%ed to i32*
store i32 3,i32*%ee,align 4
%ef=call fastcc i8*@_SMLLN11UserFileMap4spanE_90(i8*inreg%d5)
store i8*%ef,i8**%e,align 8
%eg=call i8*@sml_alloc(i32 inreg 20)#0
%eh=getelementptr inbounds i8,i8*%eg,i64 -4
%ei=bitcast i8*%eh to i32*
store i32 1342177296,i32*%ei,align 4
%ej=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%ek=bitcast i8*%eg to i8**
store i8*%ej,i8**%ek,align 8
%el=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%em=getelementptr inbounds i8,i8*%eg,i64 8
%en=bitcast i8*%em to i8**
store i8*%el,i8**%en,align 8
%eo=getelementptr inbounds i8,i8*%eg,i64 16
%ep=bitcast i8*%eo to i32*
store i32 3,i32*%ep,align 4
%eq=call fastcc i8*@_SMLLN11UserFileMap4spanE_90(i8*inreg%eg)
store i8*%eq,i8**%f,align 8
%er=call i8*@sml_alloc(i32 inreg 20)#0
%es=getelementptr inbounds i8,i8*%er,i64 -4
%et=bitcast i8*%es to i32*
store i32 1342177296,i32*%et,align 4
store i8*%er,i8**%g,align 8
%eu=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ev=bitcast i8*%er to i8**
store i8*%eu,i8**%ev,align 8
%ew=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ex=getelementptr inbounds i8,i8*%er,i64 8
%ey=bitcast i8*%ex to i8**
store i8*%ew,i8**%ey,align 8
%ez=getelementptr inbounds i8,i8*%er,i64 16
%eA=bitcast i8*%ez to i32*
store i32 3,i32*%eA,align 4
%eB=call i8*@sml_alloc(i32 inreg 12)#0
%eC=getelementptr inbounds i8,i8*%eB,i64 -4
%eD=bitcast i8*%eC to i32*
store i32 1342177288,i32*%eD,align 4
%eE=load i8*,i8**%g,align 8
%eF=bitcast i8*%eB to i8**
store i8*%eE,i8**%eF,align 8
%eG=getelementptr inbounds i8,i8*%eB,i64 8
%eH=bitcast i8*%eG to i32*
store i32 1,i32*%eH,align 4
ret i8*%eB
eI:
store i8*null,i8**%f,align 8
store i8*null,i8**%g,align 8
store i8*null,i8**%h,align 8
store i8*null,i8**%i,align 8
%eJ=bitcast i8*%d2 to i8**
%eK=load i8*,i8**%eJ,align 8
%eL=load i8,i8*%eK,align 1
%eM=call fastcc i8*@_SMLFN6String3strE(i8 inreg%eL)
store i8*%eM,i8**%e,align 8
%eN=call i8*@sml_alloc(i32 inreg 20)#0
%eO=getelementptr inbounds i8,i8*%eN,i64 -4
%eP=bitcast i8*%eO to i32*
store i32 1342177296,i32*%eP,align 4
%eQ=bitcast i8*%eN to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[25x i8]}>,<{[4x i8],i32,[25x i8]}>*@g,i64 0,i32 2,i64 0),i8**%eQ,align 8
%eR=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%eS=getelementptr inbounds i8,i8*%eN,i64 8
%eT=bitcast i8*%eS to i8**
store i8*%eR,i8**%eT,align 8
%eU=getelementptr inbounds i8,i8*%eN,i64 16
%eV=bitcast i8*%eU to i32*
store i32 3,i32*%eV,align 4
%eW=call fastcc i8*@_SMLFN6String1_ZE(i8*inreg%eN)
store i8*%eW,i8**%e,align 8
%eX=bitcast i8**%j to i32**
%eY=load i32*,i32**%eX,align 8
store i8*null,i8**%j,align 8
%eZ=load i32,i32*%eY,align 4
%e0=call i8*@sml_alloc(i32 inreg 20)#0
%e1=bitcast i8*%e0 to i32*
%e2=getelementptr inbounds i8,i8*%e0,i64 -4
%e3=bitcast i8*%e2 to i32*
store i32 1342177296,i32*%e3,align 4
%e4=getelementptr inbounds i8,i8*%e0,i64 4
%e5=bitcast i8*%e4 to i32*
store i32 0,i32*%e5,align 1
store i32%eZ,i32*%e1,align 4
%e6=load i8*,i8**%e,align 8
%e7=getelementptr inbounds i8,i8*%e0,i64 8
%e8=bitcast i8*%e7 to i8**
store i8*%e6,i8**%e8,align 8
%e9=getelementptr inbounds i8,i8*%e0,i64 16
%fa=bitcast i8*%e9 to i32*
store i32 2,i32*%fa,align 4
%fb=call i8*@sml_alloc(i32 inreg 20)#0
%fc=getelementptr inbounds i8,i8*%fb,i64 -4
%fd=bitcast i8*%fc to i32*
store i32 1342177296,i32*%fd,align 4
store i8*%fb,i8**%f,align 8
%fe=getelementptr inbounds i8,i8*%fb,i64 4
%ff=bitcast i8*%fe to i32*
store i32 0,i32*%ff,align 1
%fg=bitcast i8*%fb to i32*
store i32%eZ,i32*%fg,align 4
%fh=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%fi=getelementptr inbounds i8,i8*%fb,i64 8
%fj=bitcast i8*%fi to i8**
store i8*%fh,i8**%fj,align 8
%fk=getelementptr inbounds i8,i8*%fb,i64 16
%fl=bitcast i8*%fk to i32*
store i32 2,i32*%fl,align 4
%fm=call i8*@sml_alloc(i32 inreg 28)#0
%fn=getelementptr inbounds i8,i8*%fm,i64 -4
%fo=bitcast i8*%fn to i32*
store i32 1342177304,i32*%fo,align 4
store i8*%fm,i8**%e,align 8
%fp=bitcast i8*%fm to i8**
store i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL81,i64 0,i32 2)to i8*),i8**%fp,align 8
%fq=getelementptr inbounds i8,i8*%fm,i64 8
%fr=bitcast i8*%fq to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[64x i8]}>,<{[4x i8],i32,[64x i8]}>*@j,i64 0,i32 2,i64 0),i8**%fr,align 8
%fs=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ft=getelementptr inbounds i8,i8*%fm,i64 16
%fu=bitcast i8*%ft to i8**
store i8*%fs,i8**%fu,align 8
%fv=getelementptr inbounds i8,i8*%fm,i64 24
%fw=bitcast i8*%fv to i32*
store i32 7,i32*%fw,align 4
%fx=call i8*@sml_alloc(i32 inreg 60)#0
%fy=getelementptr inbounds i8,i8*%fx,i64 -4
%fz=bitcast i8*%fy to i32*
store i32 1342177336,i32*%fz,align 4
%fA=getelementptr inbounds i8,i8*%fx,i64 56
%fB=bitcast i8*%fA to i32*
store i32 1,i32*%fB,align 4
%fC=load i8*,i8**%e,align 8
%fD=bitcast i8*%fx to i8**
store i8*%fC,i8**%fD,align 8
call void@sml_raise(i8*inreg%fx)#1
unreachable
}
define internal fastcc i8*@_SMLLN11UserFileMap10parseLinesE_115(i8*inreg%a,i8*inreg%b,i32 inreg%c,i8*inreg%d)#2 gc"smlsharp"{
p:
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
%k=alloca i8*,align 8
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
call void@llvm.gcroot(i8**%k,i8*null)#0
store i8*%a,i8**%j,align 8
store i8*%b,i8**%f,align 8
%l=bitcast i8**%e to i8*
%m=bitcast i8**%j to i8***
br label%n
n:
%o=phi i8*[%aq,%ap],[%b,%p]
%q=phi i8*[%ar,%ap],[%d,%p]
%r=phi i32[%as,%ap],[%c,%p]
store i8*%q,i8**%g,align 8
%s=load atomic i32,i32*@sml_check_flag unordered,align 4
%t=icmp eq i32%s,0
br i1%t,label%x,label%u
u:
call void@sml_check(i32 inreg%s)
%v=load i8*,i8**%f,align 8
%w=load i8*,i8**%g,align 8
br label%x
x:
%y=phi i8*[%w,%u],[%q,%n]
%z=phi i8*[%v,%u],[%o,%n]
store i8*null,i8**%f,align 8
store i8*%z,i8**%h,align 8
%A=call fastcc i8*@_SMLFN6TextIO9inputLineE(i8*inreg%y)
%B=icmp eq i8*%A,null
br i1%B,label%C,label%E
C:
%D=load i8*,i8**%h,align 8
ret i8*%D
E:
%F=bitcast i8*%A to i8**
%G=load i8*,i8**%F,align 8
store i8*%G,i8**%f,align 8
call void@llvm.lifetime.start.p0i8(i64 8,i8*%l)
call void@llvm.gcroot(i8**%e,i8*null)#0
%H=call i8*@sml_alloc(i32 inreg 12)#0
%I=bitcast i8*%H to i32*
%J=getelementptr inbounds i8,i8*%H,i64 -4
%K=bitcast i8*%J to i32*
store i32 1342177288,i32*%K,align 4
store i8*%H,i8**%e,align 8
store i32%r,i32*%I,align 4
%L=getelementptr inbounds i8,i8*%H,i64 8
%M=bitcast i8*%L to i32*
store i32 0,i32*%M,align 4
%N=call i8*@sml_alloc(i32 inreg 28)#0
%O=getelementptr inbounds i8,i8*%N,i64 -4
%P=bitcast i8*%O to i32*
store i32 1342177304,i32*%P,align 4
%Q=load i8*,i8**%e,align 8
%R=bitcast i8*%N to i8**
store i8*%Q,i8**%R,align 8
%S=getelementptr inbounds i8,i8*%N,i64 8
%T=bitcast i8*%S to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11UserFileMap9parseLineE_112 to void(...)*),void(...)**%T,align 8
%U=getelementptr inbounds i8,i8*%N,i64 16
%V=bitcast i8*%U to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11UserFileMap9parseLineE_112 to void(...)*),void(...)**%V,align 8
%W=getelementptr inbounds i8,i8*%N,i64 24
%X=bitcast i8*%W to i32*
store i32 -2147483647,i32*%X,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%l)
store i8*%Q,i8**%i,align 8
%Y=call i8*@sml_alloc(i32 inreg 20)#0
%Z=getelementptr inbounds i8,i8*%Y,i64 -4
%aa=bitcast i8*%Z to i32*
store i32 1342177296,i32*%aa,align 4
%ab=getelementptr inbounds i8,i8*%Y,i64 12
%ac=bitcast i8*%ab to i32*
store i32 0,i32*%ac,align 1
%ad=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ae=bitcast i8*%Y to i8**
store i8*%ad,i8**%ae,align 8
%af=getelementptr inbounds i8,i8*%Y,i64 8
%ag=bitcast i8*%af to i32*
store i32 0,i32*%ag,align 4
%ah=getelementptr inbounds i8,i8*%Y,i64 16
%ai=bitcast i8*%ah to i32*
store i32 1,i32*%ai,align 4
%aj=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%ak=call fastcc i8*@_SMLLN11UserFileMap9parseLineE_112(i8*inreg%aj,i8*inreg%Y)
%al=icmp eq i8*%ak,null
br i1%al,label%am,label%at
am:
%an=load i8*,i8**%g,align 8
%ao=load i8*,i8**%h,align 8
store i8*null,i8**%g,align 8
store i8*null,i8**%h,align 8
br label%ap
ap:
%aq=phi i8*[%ao,%am],[%aS,%at]
%ar=phi i8*[%an,%am],[%aT,%at]
store i8*%aq,i8**%f,align 8
%as=add nsw i32%r,1
br label%n
at:
%au=bitcast i8*%ak to i8**
%av=load i8*,i8**%au,align 8
%aw=getelementptr inbounds i8,i8*%av,i64 8
%ax=bitcast i8*%aw to i8**
%ay=load i8*,i8**%ax,align 8
store i8*%ay,i8**%i,align 8
%az=load i8**,i8***%m,align 8
%aA=load i8*,i8**%az,align 8
store i8*%aA,i8**%k,align 8
%aB=bitcast i8*%av to i8**
%aC=load i8*,i8**%aB,align 8
%aD=call fastcc i8*@_SMLFN8Filename10componentsE(i8*inreg%aC)
store i8*%aD,i8**%f,align 8
%aE=call i8*@sml_alloc(i32 inreg 28)#0
%aF=getelementptr inbounds i8,i8*%aE,i64 -4
%aG=bitcast i8*%aF to i32*
store i32 1342177304,i32*%aG,align 4
%aH=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%aI=bitcast i8*%aE to i8**
store i8*%aH,i8**%aI,align 8
%aJ=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aK=getelementptr inbounds i8,i8*%aE,i64 8
%aL=bitcast i8*%aK to i8**
store i8*%aJ,i8**%aL,align 8
%aM=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%aN=getelementptr inbounds i8,i8*%aE,i64 16
%aO=bitcast i8*%aN to i8**
store i8*%aM,i8**%aO,align 8
%aP=getelementptr inbounds i8,i8*%aE,i64 24
%aQ=bitcast i8*%aP to i32*
store i32 7,i32*%aQ,align 4
%aR=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
%aS=call fastcc i8*@_SMLLN11UserFileMap3addE_82(i8*inreg%aR,i8*inreg%aE)
%aT=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
br label%ap
}
define internal fastcc i8*@_SMLLN11UserFileMap4loadE_116(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"personality i32(...)*@sml_personality{
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
%h=load i8*,i8**%c,align 8
br label%i
i:
%j=phi i8*[%h,%g],[%b,%k]
store i8*null,i8**%c,align 8
%l=call fastcc i8*@_SMLFN8Filename6TextIO6openInE(i8*inreg%j)
store i8*%l,i8**%c,align 8
%m=load i8*,i8**%d,align 8
%n=getelementptr inbounds i8,i8*%m,i64 8
%o=bitcast i8*%n to i8**
%p=load i8*,i8**%o,align 8
store i8*null,i8**%d,align 8
%q=bitcast i8*%m to i8**
%r=load i8*,i8**%q,align 8
%s=invoke fastcc i8*@_SMLLN11UserFileMap10parseLinesE_115(i8*inreg%p,i8*inreg%r,i32 inreg 1,i8*inreg%l)
to label%t unwind label%w
t:
store i8*%s,i8**%d,align 8
%u=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
call fastcc void@_SMLFN6TextIO7closeInE(i8*inreg%u)
%v=load i8*,i8**%d,align 8
ret i8*%v
w:
%x=landingpad{i8*,i8*}
catch i8*null
%y=extractvalue{i8*,i8*}%x,1
%z=bitcast i8*%y to i8**
%A=load i8*,i8**%z,align 8
store i8*%A,i8**%d,align 8
%B=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
call fastcc void@_SMLFN6TextIO7closeInE(i8*inreg%B)
%C=call i8*@sml_alloc(i32 inreg 60)#0
%D=getelementptr inbounds i8,i8*%C,i64 -4
%E=bitcast i8*%D to i32*
store i32 1342177336,i32*%E,align 4
%F=getelementptr inbounds i8,i8*%C,i64 56
%G=bitcast i8*%F to i32*
store i32 1,i32*%G,align 4
%H=load i8*,i8**%d,align 8
%I=bitcast i8*%C to i8**
store i8*%H,i8**%I,align 8
call void@sml_raise(i8*inreg%C)#1
unreachable
}
define fastcc i8*@_SMLFN11UserFileMap4loadE(i8*inreg%a)local_unnamed_addr#2 gc"smlsharp"{
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
%j=load i8**,i8***bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar4640b8438598f26f_UserFileMap,i64 0,i32 2,i64 0)to i8***),align 8
%k=load i8*,i8**%j,align 8
%l=tail call fastcc i8*@_SMLLN11UserFileMap4loadE_116(i8*inreg%k,i8*inreg%h)
ret i8*%l
}
define fastcc i8*@_SMLFN11UserFileMap4findE(i8*inreg%a)#2 gc"smlsharp"{
n:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
store i8*%a,i8**%f,align 8
%h=load atomic i32,i32*@sml_check_flag unordered,align 4
%i=icmp eq i32%h,0
br i1%i,label%l,label%j
j:
call void@sml_check(i32 inreg%h)
%k=load i8*,i8**%f,align 8
br label%l
l:
%m=phi i8*[%k,%j],[%a,%n]
%o=bitcast i8*%m to i8**
%p=load i8*,i8**%o,align 8
store i8*%p,i8**%f,align 8
%q=getelementptr inbounds i8,i8*%m,i64 8
%r=bitcast i8*%q to i8**
%s=load i8*,i8**%r,align 8
%t=call fastcc i8*@_SMLFN8Filename10componentsE(i8*inreg%s)
store i8*%t,i8**%g,align 8
%u=call i8*@sml_alloc(i32 inreg 20)#0
%v=getelementptr inbounds i8,i8*%u,i64 -4
%w=bitcast i8*%v to i32*
store i32 1342177296,i32*%w,align 4
%x=load i8*,i8**%f,align 8
%y=bitcast i8*%u to i8**
store i8*%x,i8**%y,align 8
%z=load i8*,i8**%g,align 8
%A=getelementptr inbounds i8,i8*%u,i64 8
%B=bitcast i8*%A to i8**
store i8*%z,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%u,i64 16
%D=bitcast i8*%C to i32*
store i32 3,i32*%D,align 4
%E=bitcast i8**%b to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%E)
%F=bitcast i8**%c to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%F)
%G=bitcast i8**%d to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%G)
%H=bitcast i8**%e to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%H)
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
br label%I
I:
%J=phi i8*[%aF,%aC],[%u,%l]
store i8*%J,i8**%b,align 8
%K=load atomic i32,i32*@sml_check_flag unordered,align 4
%L=icmp eq i32%K,0
br i1%L,label%O,label%M
M:
call void@sml_check(i32 inreg%K)
%N=load i8*,i8**%b,align 8
br label%O
O:
%P=phi i8*[%N,%M],[%J,%I]
%Q=bitcast i8*%P to i8**
%R=load i8*,i8**%Q,align 8
%S=getelementptr inbounds i8,i8*%R,i64 8
%T=bitcast i8*%S to i8**
%U=load i8*,i8**%T,align 8
store i8*%U,i8**%b,align 8
%V=getelementptr inbounds i8,i8*%P,i64 8
%W=bitcast i8*%V to i8**
%X=load i8*,i8**%W,align 8
%Y=icmp eq i8*%X,null
br i1%Y,label%Z,label%ac
Z:
%aa=bitcast i8*%R to i8**
%ab=load i8*,i8**%aa,align 8
call void@llvm.lifetime.end.p0i8(i64 8,i8*%E)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%F)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%G)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%H)
br label%aP
ac:
%ad=bitcast i8*%X to i8**
%ae=load i8*,i8**%ad,align 8
store i8*%ae,i8**%c,align 8
%af=getelementptr inbounds i8,i8*%X,i64 8
%ag=bitcast i8*%af to i8**
%ah=load i8*,i8**%ag,align 8
store i8*%ah,i8**%d,align 8
%ai=call fastcc i8*@_SMLFN8Filename3Map4findE(i32 inreg 1,i32 inreg 8)
%aj=getelementptr inbounds i8,i8*%ai,i64 16
%ak=bitcast i8*%aj to i8*(i8*,i8*)**
%al=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ak,align 8
%am=bitcast i8*%ai to i8**
%an=load i8*,i8**%am,align 8
store i8*%an,i8**%e,align 8
%ao=call i8*@sml_alloc(i32 inreg 20)#0
%ap=getelementptr inbounds i8,i8*%ao,i64 -4
%aq=bitcast i8*%ap to i32*
store i32 1342177296,i32*%aq,align 4
%ar=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%as=bitcast i8*%ao to i8**
store i8*%ar,i8**%as,align 8
%at=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%au=getelementptr inbounds i8,i8*%ao,i64 8
%av=bitcast i8*%au to i8**
store i8*%at,i8**%av,align 8
%aw=getelementptr inbounds i8,i8*%ao,i64 16
%ax=bitcast i8*%aw to i32*
store i32 3,i32*%ax,align 4
%ay=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%az=call fastcc i8*%al(i8*inreg%ay,i8*inreg%ao)
%aA=icmp eq i8*%az,null
br i1%aA,label%aB,label%aC
aB:
call void@llvm.lifetime.end.p0i8(i64 8,i8*%E)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%F)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%G)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%H)
br label%aP
aC:
%aD=bitcast i8*%az to i8**
%aE=load i8*,i8**%aD,align 8
store i8*%aE,i8**%b,align 8
%aF=call i8*@sml_alloc(i32 inreg 20)#0
%aG=getelementptr inbounds i8,i8*%aF,i64 -4
%aH=bitcast i8*%aG to i32*
store i32 1342177296,i32*%aH,align 4
%aI=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%aJ=bitcast i8*%aF to i8**
store i8*%aI,i8**%aJ,align 8
%aK=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aL=getelementptr inbounds i8,i8*%aF,i64 8
%aM=bitcast i8*%aL to i8**
store i8*%aK,i8**%aM,align 8
%aN=getelementptr inbounds i8,i8*%aF,i64 16
%aO=bitcast i8*%aN to i32*
store i32 3,i32*%aO,align 4
br label%I
aP:
%aQ=phi i8*[%ab,%Z],[null,%aB]
ret i8*%aQ
}
define fastcc i8*@_SMLFN11UserFileMap8fromListE(i8*inreg%a)local_unnamed_addr#2 gc"smlsharp"{
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
%j=load i8**,i8***bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar4640b8438598f26f_UserFileMap,i64 0,i32 2,i64 1)to i8***),align 8
%k=load i8*,i8**%j,align 8
%l=tail call fastcc i8*@_SMLLN11UserFileMap8fromListE_84(i8*inreg%k,i8*inreg%h)
ret i8*%l
}
define internal fastcc i8*@_SMLLN11UserFileMap10parseLinesE_128(i8*inreg%a,i8*inreg%b,i8*inreg%c,i8*inreg%d)#2 gc"smlsharp"{
%e=bitcast i8*%c to i32*
%f=load i32,i32*%e,align 4
%g=tail call fastcc i8*@_SMLLN11UserFileMap10parseLinesE_115(i8*inreg%a,i8*inreg%b,i32 inreg%f,i8*inreg%d)
ret i8*%g
}
define internal fastcc i8*@_SMLLN11UserFileMap4findE_130(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11UserFileMap4findE(i8*inreg%b)
ret i8*%c
}
declare void@llvm.memset.p0i8.i32(i8*,i8,i32,i1)#0
declare void@llvm.lifetime.start.p0i8(i64,i8*)#0
declare void@llvm.lifetime.end.p0i8(i64,i8*)#0
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
