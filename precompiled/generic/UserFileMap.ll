@sml_check_flag=external local_unnamed_addr global i32
@_SMLZ9Subscript=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[17x i8]}><{[4x i8]zeroinitializer,i32 -2147483631,[17x i8]c"UserFileMap.Load\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[17x i8]}>,<{[4x i8],i32,[17x i8]}>*@a,i32 0,i32 0,i32 0),i32 8),i32 9,[4x i8]zeroinitializer,i32 1}>,align 8
@_SMLDL85=private constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@b,i32 0,i32 0,i32 0),i32 8)}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN11UserFileMap4findE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11UserFileMap4findE_108 to void(...)*),i32 -2147483647}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,[65x i8]}><{[4x i8]zeroinitializer,i32 -2147483583,[65x i8]c"src/compiler/compilePhases/main/main/UserFileMap.sml:67.14(1924)\00"}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[64x i8]}><{[4x i8]zeroinitializer,i32 -2147483584,[64x i8]c"src/compiler/compilePhases/main/main/UserFileMap.sml:13.12(260)\00"}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,[65x i8]}><{[4x i8]zeroinitializer,i32 -2147483583,[65x i8]c"src/compiler/compilePhases/main/main/UserFileMap.sml:58.42(1656)\00"}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,[65x i8]}><{[4x i8]zeroinitializer,i32 -2147483583,[65x i8]c"src/compiler/compilePhases/main/main/UserFileMap.sml:52.31(1460)\00"}>,align 8
@h=private unnamed_addr constant<{[4x i8],i32,[25x i8]}><{[4x i8]zeroinitializer,i32 -2147483623,[25x i8]c"unexpected character -- \00"}>,align 8
@i=private unnamed_addr constant<{[4x i8],i32,[65x i8]}><{[4x i8]zeroinitializer,i32 -2147483583,[65x i8]c"src/compiler/compilePhases/main/main/UserFileMap.sml:62.37(1776)\00"}>,align 8
@j=private unnamed_addr constant<{[4x i8],i32,[23x i8]}><{[4x i8]zeroinitializer,i32 -2147483625,[23x i8]c"unexpected end of line\00"}>,align 8
@k=private unnamed_addr constant<{[4x i8],i32,[22x i8]}><{[4x i8]zeroinitializer,i32 -2147483626,[22x i8]c"illegal operation -- \00"}>,align 8
@_SMLZN11UserFileMap4LoadE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL85,i64 0,i32 2)to i8*)
@_SMLZN11UserFileMap4findE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*)
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
to label%o unwind label%aJ
o:
%p=invoke fastcc i8*@_SMLFN8Filename3Map5emptyE(i32 inreg 1,i32 inreg 8)
to label%q unwind label%aJ
q:
store i8*%p,i8**%c,align 8
%r=call i8*@sml_alloc(i32 inreg 20)#0
%s=getelementptr inbounds i8,i8*%r,i64 -4
%t=bitcast i8*%s to i32*
store i32 1342177296,i32*%t,align 4
store i8*%r,i8**%b,align 8
%u=bitcast i8*%r to i8**
store i8*null,i8**%u,align 8
%v=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
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
store i8*%A,i8**%c,align 8
%D=load i8*,i8**%b,align 8
%E=bitcast i8*%A to i8**
store i8*%D,i8**%E,align 8
%F=getelementptr inbounds i8,i8*%A,i64 8
%G=bitcast i8*%F to i32*
store i32 1,i32*%G,align 4
%H=call i8*@sml_alloc(i32 inreg 28)#0
%I=getelementptr inbounds i8,i8*%H,i64 -4
%J=bitcast i8*%I to i32*
store i32 1342177304,i32*%J,align 4
%K=load i8*,i8**%c,align 8
%L=bitcast i8*%H to i8**
store i8*%K,i8**%L,align 8
%M=getelementptr inbounds i8,i8*%H,i64 8
%N=bitcast i8*%M to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11UserFileMap3addE_86 to void(...)*),void(...)**%N,align 8
%O=getelementptr inbounds i8,i8*%H,i64 16
%P=bitcast i8*%O to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11UserFileMap3addE_86 to void(...)*),void(...)**%P,align 8
%Q=getelementptr inbounds i8,i8*%H,i64 24
%R=bitcast i8*%Q to i32*
store i32 -2147483647,i32*%R,align 4
%S=call i8*@sml_alloc(i32 inreg 20)#0
%T=getelementptr inbounds i8,i8*%S,i64 -4
%U=bitcast i8*%T to i32*
store i32 1342177296,i32*%U,align 4
store i8*%S,i8**%d,align 8
%V=load i8*,i8**%b,align 8
%W=bitcast i8*%S to i8**
store i8*%V,i8**%W,align 8
%X=load i8*,i8**%c,align 8
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11UserFileMap8fromListE_88 to void(...)*),void(...)**%ai,align 8
%aj=getelementptr inbounds i8,i8*%ac,i64 16
%ak=bitcast i8*%aj to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11UserFileMap8fromListE_88 to void(...)*),void(...)**%ak,align 8
%al=getelementptr inbounds i8,i8*%ac,i64 24
%am=bitcast i8*%al to i32*
store i32 -2147483647,i32*%am,align 4
%an=call i8*@sml_alloc(i32 inreg 20)#0
%ao=getelementptr inbounds i8,i8*%an,i64 -4
%ap=bitcast i8*%ao to i32*
store i32 1342177296,i32*%ap,align 4
store i8*%an,i8**%d,align 8
%aq=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%ar=bitcast i8*%an to i8**
store i8*%aq,i8**%ar,align 8
%as=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
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
%aA=load i8*,i8**%d,align 8
%aB=bitcast i8*%ax to i8**
store i8*%aA,i8**%aB,align 8
%aC=getelementptr inbounds i8,i8*%ax,i64 8
%aD=bitcast i8*%aC to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11UserFileMap4loadE_105 to void(...)*),void(...)**%aD,align 8
%aE=getelementptr inbounds i8,i8*%ax,i64 16
%aF=bitcast i8*%aE to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11UserFileMap4loadE_105 to void(...)*),void(...)**%aF,align 8
%aG=getelementptr inbounds i8,i8*%ax,i64 24
%aH=bitcast i8*%aG to i32*
store i32 -2147483647,i32*%aH,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar4640b8438598f26f_UserFileMap,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar4640b8438598f26f_UserFileMap,i64 0,i32 2,i64 0),i8*inreg%ax)#0
%aI=load i8*,i8**%e,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar4640b8438598f26f_UserFileMap,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar4640b8438598f26f_UserFileMap,i64 0,i32 2,i64 1),i8*inreg%aI)#0
call void@sml_end()#0
ret void
aJ:
%aK=landingpad{i8*,i8*}
cleanup
%aL=extractvalue{i8*,i8*}%aK,1
call void@sml_save_exn(i8*inreg%aL)#0
call void@sml_end()#0
resume{i8*,i8*}%aK
}
define internal fastcc i8*@_SMLLLN11UserFileMap3addE_86(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
store i8*null,i8**%c,align 8
%r=bitcast i8*%p to i8**
%s=load i8*,i8**%r,align 8
%t=bitcast i8*%s to i8**
%u=load i8*,i8**%t,align 8
%v=icmp eq i8*%u,null
%w=getelementptr inbounds i8,i8*%s,i64 8
%x=bitcast i8*%w to i8**
%y=load i8*,i8**%x,align 8
br i1%v,label%z,label%Z
z:
store i8*%y,i8**%c,align 8
%A=getelementptr inbounds i8,i8*%p,i64 8
%B=bitcast i8*%A to i8**
%C=load i8*,i8**%B,align 8
%D=icmp eq i8*%C,null
br i1%D,label%E,label%af
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
%aa=getelementptr inbounds i8,i8*%p,i64 8
%ab=bitcast i8*%aa to i8**
%ac=load i8*,i8**%ab,align 8
%ad=icmp eq i8*%ac,null
br i1%ad,label%ae,label%af
ae:
ret i8*%s
af:
%ag=phi i8*[%C,%z],[%ac,%Z]
%ah=getelementptr inbounds i8,i8*%p,i64 16
%ai=getelementptr inbounds i8,i8*%ag,i64 8
%aj=bitcast i8*%ah to i8**
%ak=bitcast i8*%ai to i8**
%al=bitcast i8*%ag to i8**
%am=load i8*,i8**%aj,align 8
%an=load i8*,i8**%ak,align 8
%ao=load i8*,i8**%al,align 8
store i8*%y,i8**%c,align 8
store i8*%u,i8**%d,align 8
store i8*%ao,i8**%e,align 8
store i8*%an,i8**%f,align 8
store i8*%am,i8**%g,align 8
%ap=call fastcc i8*@_SMLFN8Filename3Map4findE(i32 inreg 1,i32 inreg 8)
%aq=getelementptr inbounds i8,i8*%ap,i64 16
%ar=bitcast i8*%aq to i8*(i8*,i8*)**
%as=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ar,align 8
%at=bitcast i8*%ap to i8**
%au=load i8*,i8**%at,align 8
store i8*%au,i8**%h,align 8
%av=call i8*@sml_alloc(i32 inreg 20)#0
%aw=getelementptr inbounds i8,i8*%av,i64 -4
%ax=bitcast i8*%aw to i32*
store i32 1342177296,i32*%ax,align 4
%ay=load i8*,i8**%c,align 8
%az=bitcast i8*%av to i8**
store i8*%ay,i8**%az,align 8
%aA=load i8*,i8**%e,align 8
%aB=getelementptr inbounds i8,i8*%av,i64 8
%aC=bitcast i8*%aB to i8**
store i8*%aA,i8**%aC,align 8
%aD=getelementptr inbounds i8,i8*%av,i64 16
%aE=bitcast i8*%aD to i32*
store i32 3,i32*%aE,align 4
%aF=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%aG=call fastcc i8*%as(i8*inreg%aF,i8*inreg%av)
%aH=icmp eq i8*%aG,null
%aI=bitcast i8*%aG to i8**
%aJ=bitcast i8**%i to i8***
%aK=load i8**,i8***%aJ,align 8
%aL=select i1%aH,i8**%aK,i8**%aI
%aM=load i8*,i8**%aL,align 8
store i8*%aM,i8**%h,align 8
%aN=call fastcc i8*@_SMLFN8Filename3Map6insertE(i32 inreg 1,i32 inreg 8)
%aO=getelementptr inbounds i8,i8*%aN,i64 16
%aP=bitcast i8*%aO to i8*(i8*,i8*)**
%aQ=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aP,align 8
%aR=bitcast i8*%aN to i8**
%aS=load i8*,i8**%aR,align 8
store i8*%aS,i8**%j,align 8
%aT=call i8*@sml_alloc(i32 inreg 28)#0
%aU=getelementptr inbounds i8,i8*%aT,i64 -4
%aV=bitcast i8*%aU to i32*
store i32 1342177304,i32*%aV,align 4
%aW=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%aX=bitcast i8*%aT to i8**
store i8*%aW,i8**%aX,align 8
%aY=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aZ=getelementptr inbounds i8,i8*%aT,i64 8
%a0=bitcast i8*%aZ to i8**
store i8*%aY,i8**%a0,align 8
%a1=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%a2=getelementptr inbounds i8,i8*%aT,i64 16
%a3=bitcast i8*%a2 to i8**
store i8*%a1,i8**%a3,align 8
%a4=getelementptr inbounds i8,i8*%aT,i64 24
%a5=bitcast i8*%a4 to i32*
store i32 7,i32*%a5,align 4
%a6=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%a7=call fastcc i8*@_SMLLLN11UserFileMap3addE_86(i8*inreg%a6,i8*inreg%aT)
store i8*%a7,i8**%f,align 8
%a8=call i8*@sml_alloc(i32 inreg 28)#0
%a9=getelementptr inbounds i8,i8*%a8,i64 -4
%ba=bitcast i8*%a9 to i32*
store i32 1342177304,i32*%ba,align 4
%bb=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bc=bitcast i8*%a8 to i8**
store i8*%bb,i8**%bc,align 8
%bd=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%be=getelementptr inbounds i8,i8*%a8,i64 8
%bf=bitcast i8*%be to i8**
store i8*%bd,i8**%bf,align 8
%bg=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bh=getelementptr inbounds i8,i8*%a8,i64 16
%bi=bitcast i8*%bh to i8**
store i8*%bg,i8**%bi,align 8
%bj=getelementptr inbounds i8,i8*%a8,i64 24
%bk=bitcast i8*%bj to i32*
store i32 7,i32*%bk,align 4
%bl=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%bm=call fastcc i8*%aQ(i8*inreg%bl,i8*inreg%a8)
store i8*%bm,i8**%c,align 8
%bn=call i8*@sml_alloc(i32 inreg 20)#0
%bo=getelementptr inbounds i8,i8*%bn,i64 -4
%bp=bitcast i8*%bo to i32*
store i32 1342177296,i32*%bp,align 4
%bq=load i8*,i8**%d,align 8
%br=bitcast i8*%bn to i8**
store i8*%bq,i8**%br,align 8
%bs=load i8*,i8**%c,align 8
%bt=getelementptr inbounds i8,i8*%bn,i64 8
%bu=bitcast i8*%bt to i8**
store i8*%bs,i8**%bu,align 8
%bv=getelementptr inbounds i8,i8*%bn,i64 16
%bw=bitcast i8*%bv to i32*
store i32 3,i32*%bw,align 4
ret i8*%bn
}
define internal fastcc i8*@_SMLLLN11UserFileMap8fromListE_87(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
%l=load i8*,i8**%c,align 8
%m=bitcast i8**%d to i8***
%n=load i8**,i8***%m,align 8
br label%o
o:
%p=phi i8**[%n,%k],[%j,%i]
%q=phi i8*[%l,%k],[%b,%i]
%r=bitcast i8*%q to i8**
%s=load i8*,i8**%r,align 8
%t=bitcast i8*%s to i8**
%u=load i8*,i8**%t,align 8
%v=getelementptr inbounds i8,i8*%s,i64 8
%w=bitcast i8*%v to i8**
%x=load i8*,i8**%w,align 8
store i8*%x,i8**%c,align 8
%y=load i8*,i8**%p,align 8
store i8*%y,i8**%f,align 8
%z=getelementptr inbounds i8,i8*%q,i64 8
%A=bitcast i8*%z to i8**
%B=load i8*,i8**%A,align 8
store i8*%B,i8**%d,align 8
%C=call fastcc i8*@_SMLFN8Filename10componentsE(i8*inreg%u)
store i8*%C,i8**%e,align 8
%D=call i8*@sml_alloc(i32 inreg 28)#0
%E=getelementptr inbounds i8,i8*%D,i64 -4
%F=bitcast i8*%E to i32*
store i32 1342177304,i32*%F,align 4
%G=load i8*,i8**%d,align 8
%H=bitcast i8*%D to i8**
store i8*%G,i8**%H,align 8
%I=load i8*,i8**%e,align 8
%J=getelementptr inbounds i8,i8*%D,i64 8
%K=bitcast i8*%J to i8**
store i8*%I,i8**%K,align 8
%L=load i8*,i8**%c,align 8
%M=getelementptr inbounds i8,i8*%D,i64 16
%N=bitcast i8*%M to i8**
store i8*%L,i8**%N,align 8
%O=getelementptr inbounds i8,i8*%D,i64 24
%P=bitcast i8*%O to i32*
store i32 7,i32*%P,align 4
%Q=load i8*,i8**%f,align 8
%R=tail call fastcc i8*@_SMLLLN11UserFileMap3addE_86(i8*inreg%Q,i8*inreg%D)
ret i8*%R
}
define internal fastcc i8*@_SMLLLN11UserFileMap8fromListE_88(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11UserFileMap8fromListE_87 to void(...)*),void(...)**%I,align 8
%J=getelementptr inbounds i8,i8*%C,i64 16
%K=bitcast i8*%J to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11UserFileMap8fromListE_87 to void(...)*),void(...)**%K,align 8
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
define fastcc i8*@_SMLFN11UserFileMap4findE(i8*inreg%a)#2 gc"smlsharp"{
y:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
%f=bitcast i8*%a to i8**
%g=load i8*,i8**%f,align 8
store i8*%g,i8**%b,align 8
%h=getelementptr inbounds i8,i8*%a,i64 8
%i=bitcast i8*%h to i8**
%j=load i8*,i8**%i,align 8
%k=call fastcc i8*@_SMLFN8Filename10componentsE(i8*inreg%j)
store i8*%k,i8**%c,align 8
%l=call i8*@sml_alloc(i32 inreg 20)#0
%m=getelementptr inbounds i8,i8*%l,i64 -4
%n=bitcast i8*%m to i32*
store i32 1342177296,i32*%n,align 4
%o=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%p=bitcast i8*%l to i8**
store i8*%o,i8**%p,align 8
%q=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%r=getelementptr inbounds i8,i8*%l,i64 8
%s=bitcast i8*%r to i8**
store i8*%q,i8**%s,align 8
%t=getelementptr inbounds i8,i8*%l,i64 16
%u=bitcast i8*%t to i32*
store i32 3,i32*%u,align 4
%v=bitcast i8**%b to i8***
br label%w
w:
%x=phi i8*[%az,%at],[%o,%y]
%z=phi i8*[%aw,%at],[%l,%y]
store i8*%z,i8**%b,align 8
%A=load atomic i32,i32*@sml_check_flag unordered,align 4
%B=icmp eq i32%A,0
br i1%B,label%G,label%C
C:
call void@sml_check(i32 inreg%A)
%D=load i8**,i8***%v,align 8
%E=load i8*,i8**%D,align 8
%F=bitcast i8**%D to i8*
br label%G
G:
%H=phi i8*[%F,%C],[%z,%w]
%I=phi i8*[%E,%C],[%x,%w]
%J=bitcast i8*%I to i8**
%K=load i8*,i8**%J,align 8
%L=getelementptr inbounds i8,i8*%I,i64 8
%M=bitcast i8*%L to i8**
%N=load i8*,i8**%M,align 8
store i8*%N,i8**%c,align 8
%O=getelementptr inbounds i8,i8*%H,i64 8
%P=bitcast i8*%O to i8**
%Q=load i8*,i8**%P,align 8
%R=icmp eq i8*%Q,null
br i1%R,label%S,label%U
S:
%T=phi i8*[%K,%G],[null,%U]
ret i8*%T
U:
%V=bitcast i8*%Q to i8**
%W=load i8*,i8**%V,align 8
store i8*%W,i8**%b,align 8
%X=getelementptr inbounds i8,i8*%Q,i64 8
%Y=bitcast i8*%X to i8**
%Z=load i8*,i8**%Y,align 8
store i8*%Z,i8**%d,align 8
%aa=call fastcc i8*@_SMLFN8Filename3Map4findE(i32 inreg 1,i32 inreg 8)
%ab=getelementptr inbounds i8,i8*%aa,i64 16
%ac=bitcast i8*%ab to i8*(i8*,i8*)**
%ad=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ac,align 8
%ae=bitcast i8*%aa to i8**
%af=load i8*,i8**%ae,align 8
store i8*%af,i8**%e,align 8
%ag=call i8*@sml_alloc(i32 inreg 20)#0
%ah=getelementptr inbounds i8,i8*%ag,i64 -4
%ai=bitcast i8*%ah to i32*
store i32 1342177296,i32*%ai,align 4
%aj=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ak=bitcast i8*%ag to i8**
store i8*%aj,i8**%ak,align 8
%al=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%am=getelementptr inbounds i8,i8*%ag,i64 8
%an=bitcast i8*%am to i8**
store i8*%al,i8**%an,align 8
%ao=getelementptr inbounds i8,i8*%ag,i64 16
%ap=bitcast i8*%ao to i32*
store i32 3,i32*%ap,align 4
%aq=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ar=call fastcc i8*%ad(i8*inreg%aq,i8*inreg%ag)
%as=icmp eq i8*%ar,null
br i1%as,label%S,label%at
at:
%au=bitcast i8*%ar to i8**
%av=load i8*,i8**%au,align 8
store i8*%av,i8**%b,align 8
%aw=call i8*@sml_alloc(i32 inreg 20)#0
%ax=getelementptr inbounds i8,i8*%aw,i64 -4
%ay=bitcast i8*%ax to i32*
store i32 1342177296,i32*%ay,align 4
%az=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%aA=bitcast i8*%aw to i8**
store i8*%az,i8**%aA,align 8
%aB=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aC=getelementptr inbounds i8,i8*%aw,i64 8
%aD=bitcast i8*%aC to i8**
store i8*%aB,i8**%aD,align 8
%aE=getelementptr inbounds i8,i8*%aw,i64 16
%aF=bitcast i8*%aE to i32*
store i32 3,i32*%aF,align 4
br label%w
}
define internal fastcc i8*@_SMLLLN11UserFileMap6splitlE_92(i8 inreg%a,i8*inreg%b)unnamed_addr#2 gc"smlsharp"{
i:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
%f=bitcast i8**%c to i8***
br label%g
g:
%h=phi i8*[%ad,%a9],[%b,%i]
store i8*%h,i8**%c,align 8
%j=load atomic i32,i32*@sml_check_flag unordered,align 4
%k=icmp eq i32%j,0
%l=bitcast i8*%h to i8**
br i1%k,label%o,label%m
m:
call void@sml_check(i32 inreg%j)
%n=load i8**,i8***%f,align 8
br label%o
o:
%p=phi i8**[%n,%m],[%l,%g]
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%d,align 8
store i8*null,i8**%c,align 8
%r=getelementptr inbounds i8*,i8**%p,i64 1
%s=bitcast i8**%r to i32*
%t=load i32,i32*%s,align 4
%u=getelementptr inbounds i8,i8*%q,i64 -4
%v=bitcast i8*%u to i32*
%w=load i32,i32*%v,align 4
%x=and i32%w,268435455
%y=add nsw i32%x,-1
%z=icmp sgt i32%y,%t
br i1%z,label%V,label%A
A:
%B=call i8*@sml_alloc(i32 inreg 20)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177296,i32*%D,align 4
store i8*%B,i8**%c,align 8
%E=getelementptr inbounds i8,i8*%B,i64 12
%F=bitcast i8*%E to i32*
store i32 0,i32*%F,align 1
%G=load i8*,i8**%d,align 8
%H=bitcast i8*%B to i8**
store i8*null,i8**%d,align 8
store i8*%G,i8**%H,align 8
%I=getelementptr inbounds i8,i8*%B,i64 8
%J=bitcast i8*%I to i32*
store i32%t,i32*%J,align 4
%K=getelementptr inbounds i8,i8*%B,i64 16
%L=bitcast i8*%K to i32*
store i32 1,i32*%L,align 4
%M=call i8*@sml_alloc(i32 inreg 20)#0
%N=getelementptr inbounds i8,i8*%M,i64 -4
%O=bitcast i8*%N to i32*
store i32 1342177296,i32*%O,align 4
%P=load i8*,i8**%c,align 8
%Q=bitcast i8*%M to i8**
store i8*%P,i8**%Q,align 8
%R=getelementptr inbounds i8,i8*%M,i64 8
%S=bitcast i8*%R to i8**
store i8*null,i8**%S,align 8
%T=getelementptr inbounds i8,i8*%M,i64 16
%U=bitcast i8*%T to i32*
store i32 3,i32*%U,align 4
ret i8*%M
V:
%W=icmp slt i32%t,0
br i1%W,label%ag,label%X
X:
%Y=sext i32%t to i64
%Z=getelementptr inbounds i8,i8*%q,i64%Y
%aa=load i8,i8*%Z,align 1
%ab=icmp eq i8%aa,%a
%ac=add nsw i32%t,1
%ad=call i8*@sml_alloc(i32 inreg 20)#0
%ae=getelementptr inbounds i8,i8*%ad,i64 -4
%af=bitcast i8*%ae to i32*
store i32 1342177296,i32*%af,align 4
br i1%ab,label%ay,label%a9
ag:
store i8*null,i8**%d,align 8
%ah=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%ah,i8**%c,align 8
%ai=call i8*@sml_alloc(i32 inreg 20)#0
%aj=getelementptr inbounds i8,i8*%ai,i64 -4
%ak=bitcast i8*%aj to i32*
store i32 1342177296,i32*%ak,align 4
store i8*%ai,i8**%d,align 8
%al=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%am=bitcast i8*%ai to i8**
store i8*%al,i8**%am,align 8
%an=getelementptr inbounds i8,i8*%ai,i64 8
%ao=bitcast i8*%an to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[65x i8]}>,<{[4x i8],i32,[65x i8]}>*@d,i64 0,i32 2,i64 0),i8**%ao,align 8
%ap=getelementptr inbounds i8,i8*%ai,i64 16
%aq=bitcast i8*%ap to i32*
store i32 3,i32*%aq,align 4
%ar=call i8*@sml_alloc(i32 inreg 60)#0
%as=getelementptr inbounds i8,i8*%ar,i64 -4
%at=bitcast i8*%as to i32*
store i32 1342177336,i32*%at,align 4
%au=getelementptr inbounds i8,i8*%ar,i64 56
%av=bitcast i8*%au to i32*
store i32 1,i32*%av,align 4
%aw=load i8*,i8**%d,align 8
%ax=bitcast i8*%ar to i8**
store i8*%aw,i8**%ax,align 8
call void@sml_raise(i8*inreg%ar)#1
unreachable
ay:
store i8*%ad,i8**%e,align 8
%az=getelementptr inbounds i8,i8*%ad,i64 12
%aA=bitcast i8*%az to i32*
store i32 0,i32*%aA,align 1
%aB=load i8*,i8**%d,align 8
%aC=bitcast i8*%ad to i8**
store i8*%aB,i8**%aC,align 8
%aD=getelementptr inbounds i8,i8*%ad,i64 8
%aE=bitcast i8*%aD to i32*
store i32%ac,i32*%aE,align 4
%aF=getelementptr inbounds i8,i8*%ad,i64 16
%aG=bitcast i8*%aF to i32*
store i32 1,i32*%aG,align 4
%aH=call i8*@sml_alloc(i32 inreg 12)#0
%aI=getelementptr inbounds i8,i8*%aH,i64 -4
%aJ=bitcast i8*%aI to i32*
store i32 1342177288,i32*%aJ,align 4
store i8*%aH,i8**%c,align 8
%aK=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aL=bitcast i8*%aH to i8**
store i8*%aK,i8**%aL,align 8
%aM=getelementptr inbounds i8,i8*%aH,i64 8
%aN=bitcast i8*%aM to i32*
store i32 1,i32*%aN,align 4
%aO=call i8*@sml_alloc(i32 inreg 20)#0
%aP=getelementptr inbounds i8,i8*%aO,i64 -4
%aQ=bitcast i8*%aP to i32*
store i32 1342177296,i32*%aQ,align 4
store i8*%aO,i8**%e,align 8
%aR=getelementptr inbounds i8,i8*%aO,i64 12
%aS=bitcast i8*%aR to i32*
store i32 0,i32*%aS,align 1
%aT=load i8*,i8**%d,align 8
%aU=bitcast i8*%aO to i8**
store i8*null,i8**%d,align 8
store i8*%aT,i8**%aU,align 8
%aV=getelementptr inbounds i8,i8*%aO,i64 8
%aW=bitcast i8*%aV to i32*
store i32%t,i32*%aW,align 4
%aX=getelementptr inbounds i8,i8*%aO,i64 16
%aY=bitcast i8*%aX to i32*
store i32 1,i32*%aY,align 4
%aZ=call i8*@sml_alloc(i32 inreg 20)#0
%a0=getelementptr inbounds i8,i8*%aZ,i64 -4
%a1=bitcast i8*%a0 to i32*
store i32 1342177296,i32*%a1,align 4
%a2=load i8*,i8**%e,align 8
%a3=bitcast i8*%aZ to i8**
store i8*%a2,i8**%a3,align 8
%a4=load i8*,i8**%c,align 8
%a5=getelementptr inbounds i8,i8*%aZ,i64 8
%a6=bitcast i8*%a5 to i8**
store i8*%a4,i8**%a6,align 8
%a7=getelementptr inbounds i8,i8*%aZ,i64 16
%a8=bitcast i8*%a7 to i32*
store i32 3,i32*%a8,align 4
ret i8*%aZ
a9:
%ba=getelementptr inbounds i8,i8*%ad,i64 12
%bb=bitcast i8*%ba to i32*
store i32 0,i32*%bb,align 1
%bc=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bd=bitcast i8*%ad to i8**
store i8*%bc,i8**%bd,align 8
%be=getelementptr inbounds i8,i8*%ad,i64 8
%bf=bitcast i8*%be to i32*
store i32%ac,i32*%bf,align 4
%bg=getelementptr inbounds i8,i8*%ad,i64 16
%bh=bitcast i8*%bg to i32*
store i32 1,i32*%bh,align 4
br label%g
}
define internal fastcc i8*@_SMLLLN11UserFileMap4loadE_105(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"personality i32(...)*@sml_personality{
v:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
%k=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
call void@llvm.gcroot(i8**%k,i8*null)#0
store i8*%a,i8**%k,align 8
%l=call fastcc i8*@_SMLFN8Filename6TextIO6openInE(i8*inreg%b)
store i8*%l,i8**%c,align 8
%m=bitcast i8**%k to i8***
%n=load i8**,i8***%m,align 8
%o=load i8*,i8**%n,align 8
store i8*%o,i8**%d,align 8
%p=bitcast i8**%e to i8***
%q=bitcast i8**%i to i8***
%r=bitcast i8**%f to i8***
%s=bitcast i8**%g to i8***
br label%t
t:
%u=phi i32[1,%v],[%kh,%kg]
%w=load atomic i32,i32*@sml_check_flag unordered,align 4
%x=icmp eq i32%w,0
br i1%x,label%z,label%y
y:
call void@sml_check(i32 inreg%w)
br label%z
z:
%A=load i8*,i8**%c,align 8
%B=invoke fastcc i8*@_SMLFN6TextIO9inputLineE(i8*inreg%A)
to label%C unwind label%kQ
C:
%D=icmp eq i8*%B,null
br i1%D,label%E,label%H
E:
store i8*null,i8**%k,align 8
%F=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
call fastcc void@_SMLFN6TextIO7closeInE(i8*inreg%F)
%G=load i8*,i8**%d,align 8
ret i8*%G
H:
%I=bitcast i8*%B to i8**
%J=load i8*,i8**%I,align 8
store i8*%J,i8**%e,align 8
%K=call i8*@sml_alloc(i32 inreg 20)#0
%L=getelementptr inbounds i8,i8*%K,i64 -4
%M=bitcast i8*%L to i32*
store i32 1342177296,i32*%M,align 4
%N=getelementptr inbounds i8,i8*%K,i64 12
%O=bitcast i8*%N to i32*
store i32 0,i32*%O,align 1
%P=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
br label%Q
Q:
%R=phi i8*[%aN,%aL],[%K,%H]
%S=phi i8*[%aS,%aL],[%P,%H]
%T=phi i32[%aM,%aL],[0,%H]
%U=bitcast i8*%R to i8**
store i8*%S,i8**%U,align 8
%V=getelementptr inbounds i8,i8*%R,i64 8
%W=bitcast i8*%V to i32*
store i32%T,i32*%W,align 4
%X=getelementptr inbounds i8,i8*%R,i64 16
%Y=bitcast i8*%X to i32*
store i32 1,i32*%Y,align 4
store i8*%R,i8**%e,align 8
%Z=load atomic i32,i32*@sml_check_flag unordered,align 4
%aa=icmp eq i32%Z,0
%ab=bitcast i8*%R to i8**
br i1%aa,label%af,label%ac
ac:
call void@sml_check(i32 inreg%Z)
%ad=load i8**,i8***%p,align 8
%ae=load i8*,i8**%ad,align 8
br label%af
af:
%ag=phi i8*[%ae,%ac],[%S,%Q]
%ah=phi i8**[%ad,%ac],[%ab,%Q]
store i8*%ag,i8**%f,align 8
store i8*null,i8**%e,align 8
%ai=getelementptr inbounds i8*,i8**%ah,i64 1
%aj=bitcast i8**%ai to i32*
%ak=load i32,i32*%aj,align 4
%al=getelementptr inbounds i8,i8*%ag,i64 -4
%am=bitcast i8*%al to i32*
%an=load i32,i32*%am,align 4
%ao=and i32%an,268435455
%ap=add nsw i32%ao,-1
%aq=icmp sgt i32%ap,%ak
br i1%aq,label%ar,label%aT
ar:
%as=icmp sgt i32%ak,-1
br i1%as,label%at,label%ay
at:
%au=sext i32%ak to i64
%av=getelementptr inbounds i8,i8*%ag,i64%au
%aw=load i8,i8*%av,align 1
%ax=invoke fastcc i32@_SMLFN4Char7isSpaceE(i8 inreg%aw)
to label%aJ unwind label%kO
ay:
store i8*null,i8**%f,align 8
store i8*null,i8**%k,align 8
%az=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%az,i8**%d,align 8
%aA=call i8*@sml_alloc(i32 inreg 20)#0
%aB=getelementptr inbounds i8,i8*%aA,i64 -4
%aC=bitcast i8*%aB to i32*
store i32 1342177296,i32*%aC,align 4
%aD=load i8*,i8**%d,align 8
%aE=bitcast i8*%aA to i8**
store i8*%aD,i8**%aE,align 8
%aF=getelementptr inbounds i8,i8*%aA,i64 8
%aG=bitcast i8*%aF to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[65x i8]}>,<{[4x i8],i32,[65x i8]}>*@f,i64 0,i32 2,i64 0),i8**%aG,align 8
%aH=getelementptr inbounds i8,i8*%aA,i64 16
%aI=bitcast i8*%aH to i32*
store i32 3,i32*%aI,align 4
store i8*%aA,i8**%d,align 8
br label%kZ
aJ:
%aK=icmp eq i32%ax,0
br i1%aK,label%aT,label%aL
aL:
%aM=add nsw i32%ak,1
%aN=call i8*@sml_alloc(i32 inreg 20)#0
%aO=getelementptr inbounds i8,i8*%aN,i64 -4
%aP=bitcast i8*%aO to i32*
store i32 1342177296,i32*%aP,align 4
%aQ=getelementptr inbounds i8,i8*%aN,i64 12
%aR=bitcast i8*%aQ to i32*
store i32 0,i32*%aR,align 1
%aS=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
br label%Q
aT:
%aU=call i8*@sml_alloc(i32 inreg 20)#0
%aV=getelementptr inbounds i8,i8*%aU,i64 -4
%aW=bitcast i8*%aV to i32*
store i32 1342177296,i32*%aW,align 4
%aX=getelementptr inbounds i8,i8*%aU,i64 12
%aY=bitcast i8*%aX to i32*
store i32 0,i32*%aY,align 1
%aZ=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%a0=bitcast i8*%aU to i8**
store i8*%aZ,i8**%a0,align 8
%a1=getelementptr inbounds i8,i8*%aU,i64 8
%a2=bitcast i8*%a1 to i32*
store i32%ak,i32*%a2,align 4
%a3=getelementptr inbounds i8,i8*%aU,i64 16
%a4=bitcast i8*%a3 to i32*
store i32 1,i32*%a4,align 4
store i8*%aZ,i8**%e,align 8
%a5=getelementptr inbounds i8,i8*%aZ,i64 -4
%a6=bitcast i8*%a5 to i32*
%a7=load i32,i32*%a6,align 4
%a8=and i32%a7,268435455
%a9=add nsw i32%a8,-1
%ba=icmp sgt i32%a9,%ak
br i1%ba,label%bb,label%bo
bb:
%bc=icmp sgt i32%ak,-1
br i1%bc,label%bp,label%bd
bd:
store i8*null,i8**%e,align 8
store i8*null,i8**%k,align 8
%be=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%be,i8**%d,align 8
%bf=call i8*@sml_alloc(i32 inreg 20)#0
%bg=getelementptr inbounds i8,i8*%bf,i64 -4
%bh=bitcast i8*%bg to i32*
store i32 1342177296,i32*%bh,align 4
%bi=load i8*,i8**%d,align 8
%bj=bitcast i8*%bf to i8**
store i8*%bi,i8**%bj,align 8
%bk=getelementptr inbounds i8,i8*%bf,i64 8
%bl=bitcast i8*%bk to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[65x i8]}>,<{[4x i8],i32,[65x i8]}>*@g,i64 0,i32 2,i64 0),i8**%bl,align 8
%bm=getelementptr inbounds i8,i8*%bf,i64 16
%bn=bitcast i8*%bm to i32*
store i32 3,i32*%bn,align 4
store i8*%bf,i8**%d,align 8
br label%kZ
bo:
store i8*null,i8**%e,align 8
br label%kg
bp:
%bq=sext i32%ak to i64
%br=getelementptr inbounds i8,i8*%aZ,i64%bq
%bs=load i8,i8*%br,align 1
%bt=add nsw i32%ak,1
%bu=call i8*@sml_alloc(i32 inreg 20)#0
%bv=getelementptr inbounds i8,i8*%bu,i64 -4
%bw=bitcast i8*%bv to i32*
store i32 1342177296,i32*%bw,align 4
store i8*%bu,i8**%f,align 8
%bx=getelementptr inbounds i8,i8*%bu,i64 12
%by=bitcast i8*%bx to i32*
store i32 0,i32*%by,align 1
%bz=load i8*,i8**%e,align 8
%bA=bitcast i8*%bu to i8**
store i8*null,i8**%e,align 8
store i8*%bz,i8**%bA,align 8
%bB=getelementptr inbounds i8,i8*%bu,i64 8
%bC=bitcast i8*%bB to i32*
store i32%bt,i32*%bC,align 4
%bD=getelementptr inbounds i8,i8*%bu,i64 16
%bE=bitcast i8*%bD to i32*
store i32 1,i32*%bE,align 4
%bF=call i8*@sml_alloc(i32 inreg 20)#0
%bG=getelementptr inbounds i8,i8*%bF,i64 -4
%bH=bitcast i8*%bG to i32*
store i32 1342177296,i32*%bH,align 4
store i8*%bF,i8**%e,align 8
%bI=getelementptr inbounds i8,i8*%bF,i64 1
call void@llvm.memset.p0i8.i32(i8*%bI,i8 0,i32 7,i1 false)
store i8%bs,i8*%bF,align 1
%bJ=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bK=getelementptr inbounds i8,i8*%bF,i64 8
%bL=bitcast i8*%bK to i8**
store i8*%bJ,i8**%bL,align 8
%bM=getelementptr inbounds i8,i8*%bF,i64 16
%bN=bitcast i8*%bM to i32*
store i32 2,i32*%bN,align 4
%bO=call i8*@sml_alloc(i32 inreg 12)#0
%bP=getelementptr inbounds i8,i8*%bO,i64 -4
%bQ=bitcast i8*%bP to i32*
store i32 1342177288,i32*%bQ,align 4
%bR=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bS=bitcast i8*%bO to i8**
store i8*%bR,i8**%bS,align 8
%bT=getelementptr inbounds i8,i8*%bO,i64 8
%bU=bitcast i8*%bT to i32*
store i32 1,i32*%bU,align 4
%bV=icmp eq i8*%bO,null
br i1%bV,label%kg,label%bW
bW:
%bX=load i8,i8*%bR,align 1
%bY=icmp eq i8%bX,35
br i1%bY,label%kg,label%bZ
bZ:
%b0=getelementptr inbounds i8,i8*%bR,i64 8
%b1=bitcast i8*%b0 to i8**
%b2=load i8*,i8**%b1,align 8
%b3=icmp eq i8%bX,61
br i1%b3,label%ct,label%b4
b4:
store i8*null,i8**%d,align 8
store i8*null,i8**%k,align 8
%b5=invoke fastcc i8*@_SMLFN6String3strE(i8 inreg%bX)
to label%b6 unwind label%kS
b6:
store i8*%b5,i8**%d,align 8
%b7=call i8*@sml_alloc(i32 inreg 20)#0
%b8=getelementptr inbounds i8,i8*%b7,i64 -4
%b9=bitcast i8*%b8 to i32*
store i32 1342177296,i32*%b9,align 4
%ca=bitcast i8*%b7 to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[22x i8]}>,<{[4x i8],i32,[22x i8]}>*@k,i64 0,i32 2,i64 0),i8**%ca,align 8
%cb=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%cc=getelementptr inbounds i8,i8*%b7,i64 8
%cd=bitcast i8*%cc to i8**
store i8*%cb,i8**%cd,align 8
%ce=getelementptr inbounds i8,i8*%b7,i64 16
%cf=bitcast i8*%ce to i32*
store i32 3,i32*%cf,align 4
%cg=invoke fastcc i8*@_SMLFN6String1_ZE(i8*inreg%b7)
to label%ch unwind label%kS
ch:
store i8*%cg,i8**%d,align 8
%ci=call i8*@sml_alloc(i32 inreg 20)#0
%cj=bitcast i8*%ci to i32*
%ck=getelementptr inbounds i8,i8*%ci,i64 -4
%cl=bitcast i8*%ck to i32*
store i32 1342177296,i32*%cl,align 4
%cm=getelementptr inbounds i8,i8*%ci,i64 4
%cn=bitcast i8*%cm to i32*
store i32 0,i32*%cn,align 1
store i32%u,i32*%cj,align 4
%co=load i8*,i8**%d,align 8
%cp=getelementptr inbounds i8,i8*%ci,i64 8
%cq=bitcast i8*%cp to i8**
store i8*%co,i8**%cq,align 8
%cr=getelementptr inbounds i8,i8*%ci,i64 16
%cs=bitcast i8*%cr to i32*
store i32 2,i32*%cs,align 4
store i8*%ci,i8**%d,align 8
br label%jA
ct:
%cu=bitcast i8*%b2 to i8**
%cv=load i8*,i8**%cu,align 8
store i8*%cv,i8**%e,align 8
%cw=getelementptr inbounds i8,i8*%b2,i64 8
%cx=bitcast i8*%cw to i32*
%cy=load i32,i32*%cx,align 4
%cz=getelementptr inbounds i8,i8*%cv,i64 -4
%cA=bitcast i8*%cz to i32*
%cB=load i32,i32*%cA,align 4
%cC=and i32%cB,268435455
%cD=add nsw i32%cC,-1
%cE=icmp sgt i32%cD,%cy
br i1%cE,label%cF,label%cS
cF:
%cG=icmp sgt i32%cy,-1
br i1%cG,label%cT,label%cH
cH:
store i8*null,i8**%e,align 8
store i8*null,i8**%k,align 8
%cI=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%cI,i8**%d,align 8
%cJ=call i8*@sml_alloc(i32 inreg 20)#0
%cK=getelementptr inbounds i8,i8*%cJ,i64 -4
%cL=bitcast i8*%cK to i32*
store i32 1342177296,i32*%cL,align 4
%cM=load i8*,i8**%d,align 8
%cN=bitcast i8*%cJ to i8**
store i8*%cM,i8**%cN,align 8
%cO=getelementptr inbounds i8,i8*%cJ,i64 8
%cP=bitcast i8*%cO to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[65x i8]}>,<{[4x i8],i32,[65x i8]}>*@g,i64 0,i32 2,i64 0),i8**%cP,align 8
%cQ=getelementptr inbounds i8,i8*%cJ,i64 16
%cR=bitcast i8*%cQ to i32*
store i32 3,i32*%cR,align 4
store i8*%cJ,i8**%d,align 8
br label%kZ
cS:
store i8*null,i8**%e,align 8
br label%dq
cT:
%cU=sext i32%cy to i64
%cV=getelementptr inbounds i8,i8*%cv,i64%cU
%cW=load i8,i8*%cV,align 1
%cX=add nsw i32%cy,1
%cY=call i8*@sml_alloc(i32 inreg 20)#0
%cZ=getelementptr inbounds i8,i8*%cY,i64 -4
%c0=bitcast i8*%cZ to i32*
store i32 1342177296,i32*%c0,align 4
store i8*%cY,i8**%f,align 8
%c1=getelementptr inbounds i8,i8*%cY,i64 12
%c2=bitcast i8*%c1 to i32*
store i32 0,i32*%c2,align 1
%c3=load i8*,i8**%e,align 8
%c4=bitcast i8*%cY to i8**
store i8*null,i8**%e,align 8
store i8*%c3,i8**%c4,align 8
%c5=getelementptr inbounds i8,i8*%cY,i64 8
%c6=bitcast i8*%c5 to i32*
store i32%cX,i32*%c6,align 4
%c7=getelementptr inbounds i8,i8*%cY,i64 16
%c8=bitcast i8*%c7 to i32*
store i32 1,i32*%c8,align 4
%c9=call i8*@sml_alloc(i32 inreg 20)#0
%da=getelementptr inbounds i8,i8*%c9,i64 -4
%db=bitcast i8*%da to i32*
store i32 1342177296,i32*%db,align 4
store i8*%c9,i8**%e,align 8
%dc=getelementptr inbounds i8,i8*%c9,i64 1
call void@llvm.memset.p0i8.i32(i8*%dc,i8 0,i32 7,i1 false)
store i8%cW,i8*%c9,align 1
%dd=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%de=getelementptr inbounds i8,i8*%c9,i64 8
%df=bitcast i8*%de to i8**
store i8*%dd,i8**%df,align 8
%dg=getelementptr inbounds i8,i8*%c9,i64 16
%dh=bitcast i8*%dg to i32*
store i32 2,i32*%dh,align 4
%di=call i8*@sml_alloc(i32 inreg 12)#0
%dj=getelementptr inbounds i8,i8*%di,i64 -4
%dk=bitcast i8*%dj to i32*
store i32 1342177288,i32*%dk,align 4
%dl=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%dm=bitcast i8*%di to i8**
store i8*%dl,i8**%dm,align 8
%dn=getelementptr inbounds i8,i8*%di,i64 8
%do=bitcast i8*%dn to i32*
store i32 1,i32*%do,align 4
%dp=icmp eq i8*%di,null
br i1%dp,label%dq,label%dB
dq:
store i8*null,i8**%d,align 8
store i8*null,i8**%k,align 8
%dr=call i8*@sml_alloc(i32 inreg 20)#0
%ds=bitcast i8*%dr to i32*
%dt=getelementptr inbounds i8,i8*%dr,i64 -4
%du=bitcast i8*%dt to i32*
store i32 1342177296,i32*%du,align 4
%dv=getelementptr inbounds i8,i8*%dr,i64 4
%dw=bitcast i8*%dv to i32*
store i32 0,i32*%dw,align 1
store i32%u,i32*%ds,align 4
%dx=getelementptr inbounds i8,i8*%dr,i64 8
%dy=bitcast i8*%dx to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[23x i8]}>,<{[4x i8],i32,[23x i8]}>*@j,i64 0,i32 2,i64 0),i8**%dy,align 8
%dz=getelementptr inbounds i8,i8*%dr,i64 16
%dA=bitcast i8*%dz to i32*
store i32 2,i32*%dA,align 4
store i8*%dr,i8**%d,align 8
br label%jA
dB:
%dC=load i8,i8*%dl,align 1
%dD=getelementptr inbounds i8,i8*%dl,i64 8
%dE=bitcast i8*%dD to i8**
%dF=load i8*,i8**%dE,align 8
store i8*%dF,i8**%e,align 8
%dG=invoke fastcc i8*@_SMLLLN11UserFileMap6splitlE_92(i8 inreg%dC,i8*inreg%dF)
to label%dH unwind label%kQ
dH:
%dI=bitcast i8*%dG to i8**
%dJ=load i8*,i8**%dI,align 8
store i8*%dJ,i8**%f,align 8
%dK=getelementptr inbounds i8,i8*%dG,i64 8
%dL=bitcast i8*%dK to i8**
%dM=load i8*,i8**%dL,align 8
%dN=icmp eq i8*%dM,null
br i1%dN,label%dO,label%dZ
dO:
store i8*null,i8**%d,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%k,align 8
%dP=call i8*@sml_alloc(i32 inreg 20)#0
%dQ=bitcast i8*%dP to i32*
%dR=getelementptr inbounds i8,i8*%dP,i64 -4
%dS=bitcast i8*%dR to i32*
store i32 1342177296,i32*%dS,align 4
%dT=getelementptr inbounds i8,i8*%dP,i64 4
%dU=bitcast i8*%dT to i32*
store i32 0,i32*%dU,align 1
store i32%u,i32*%dQ,align 4
%dV=getelementptr inbounds i8,i8*%dP,i64 8
%dW=bitcast i8*%dV to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[23x i8]}>,<{[4x i8],i32,[23x i8]}>*@j,i64 0,i32 2,i64 0),i8**%dW,align 8
%dX=getelementptr inbounds i8,i8*%dP,i64 16
%dY=bitcast i8*%dX to i32*
store i32 2,i32*%dY,align 4
store i8*%dP,i8**%d,align 8
br label%jA
dZ:
%d0=bitcast i8*%dM to i8**
%d1=load i8*,i8**%d0,align 8
store i8*%d1,i8**%g,align 8
%d2=invoke fastcc i8*@_SMLLLN11UserFileMap6splitlE_92(i8 inreg%dC,i8*inreg%d1)
to label%d3 unwind label%kQ
d3:
%d4=bitcast i8*%d2 to i8**
%d5=load i8*,i8**%d4,align 8
store i8*%d5,i8**%h,align 8
%d6=getelementptr inbounds i8,i8*%d2,i64 8
%d7=bitcast i8*%d6 to i8**
%d8=load i8*,i8**%d7,align 8
%d9=icmp eq i8*%d8,null
br i1%d9,label%ea,label%gb
ea:
%eb=load i8**,i8***%p,align 8
%ec=load i8*,i8**%eb,align 8
store i8*%ec,i8**%i,align 8
store i8*null,i8**%e,align 8
%ed=getelementptr inbounds i8*,i8**%eb,i64 1
%ee=bitcast i8**%ed to i32*
%ef=load i32,i32*%ee,align 4
%eg=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%eh=getelementptr inbounds i8,i8*%eg,i64 8
%ei=bitcast i8*%eh to i32*
%ej=load i32,i32*%ei,align 4
%ek=sub nsw i32%ej,%ef
%el=call i8*@sml_alloc(i32 inreg 20)#0
%em=getelementptr inbounds i8,i8*%el,i64 -4
%en=bitcast i8*%em to i32*
store i32 1342177296,i32*%en,align 4
%eo=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%ep=bitcast i8*%el to i8**
store i8*%eo,i8**%ep,align 8
%eq=getelementptr inbounds i8,i8*%el,i64 8
%er=bitcast i8*%eq to i32*
store i32%ef,i32*%er,align 4
%es=getelementptr inbounds i8,i8*%el,i64 12
%et=bitcast i8*%es to i32*
store i32%ek,i32*%et,align 4
%eu=getelementptr inbounds i8,i8*%el,i64 16
%ev=bitcast i8*%eu to i32*
store i32 1,i32*%ev,align 4
%ew=invoke fastcc i8*@_SMLFN6String9substringE(i8*inreg%el)
to label%ex unwind label%kQ
ex:
%ey=invoke fastcc i8*@_SMLFN8Filename10fromStringE(i8*inreg%ew)
to label%ez unwind label%kQ
ez:
store i8*%ey,i8**%e,align 8
%eA=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
br label%eB
eB:
%eC=phi i8*[%ff,%fe],[%eA,%ez]
store i8*%eC,i8**%f,align 8
%eD=load atomic i32,i32*@sml_check_flag unordered,align 4
%eE=icmp eq i32%eD,0
%eF=bitcast i8*%eC to i8**
br i1%eE,label%eI,label%eG
eG:
call void@sml_check(i32 inreg%eD)
%eH=load i8**,i8***%r,align 8
br label%eI
eI:
%eJ=phi i8**[%eH,%eG],[%eF,%eB]
%eK=load i8*,i8**%eJ,align 8
store i8*%eK,i8**%h,align 8
store i8*null,i8**%f,align 8
%eL=getelementptr inbounds i8*,i8**%eJ,i64 1
%eM=bitcast i8**%eL to i32*
%eN=load i32,i32*%eM,align 4
%eO=icmp slt i32%eN,1
br i1%eO,label%fq,label%eP
eP:
%eQ=getelementptr inbounds i8,i8*%eK,i64 -4
%eR=bitcast i8*%eQ to i32*
%eS=load i32,i32*%eR,align 4
%eT=and i32%eS,268435455
%eU=icmp slt i32%eN,%eT
br i1%eU,label%eV,label%e1
eV:
%eW=add nsw i32%eN,-1
%eX=sext i32%eW to i64
%eY=getelementptr inbounds i8,i8*%eK,i64%eX
%eZ=load i8,i8*%eY,align 1
%e0=invoke fastcc i32@_SMLFN4Char7isSpaceE(i8 inreg%eZ)
to label%fc unwind label%kK
e1:
store i8*null,i8**%g,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%h,align 8
store i8*null,i8**%k,align 8
%e2=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%e2,i8**%d,align 8
%e3=call i8*@sml_alloc(i32 inreg 20)#0
%e4=getelementptr inbounds i8,i8*%e3,i64 -4
%e5=bitcast i8*%e4 to i32*
store i32 1342177296,i32*%e5,align 4
%e6=load i8*,i8**%d,align 8
%e7=bitcast i8*%e3 to i8**
store i8*%e6,i8**%e7,align 8
%e8=getelementptr inbounds i8,i8*%e3,i64 8
%e9=bitcast i8*%e8 to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[65x i8]}>,<{[4x i8],i32,[65x i8]}>*@i,i64 0,i32 2,i64 0),i8**%e9,align 8
%fa=getelementptr inbounds i8,i8*%e3,i64 16
%fb=bitcast i8*%fa to i32*
store i32 3,i32*%fb,align 4
store i8*%e3,i8**%d,align 8
br label%kZ
fc:
%fd=icmp eq i32%e0,0
br i1%fd,label%fq,label%fe
fe:
%ff=call i8*@sml_alloc(i32 inreg 20)#0
%fg=getelementptr inbounds i8,i8*%ff,i64 -4
%fh=bitcast i8*%fg to i32*
store i32 1342177296,i32*%fh,align 4
%fi=getelementptr inbounds i8,i8*%ff,i64 12
%fj=bitcast i8*%fi to i32*
store i32 0,i32*%fj,align 1
%fk=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%fl=bitcast i8*%ff to i8**
store i8*%fk,i8**%fl,align 8
%fm=getelementptr inbounds i8,i8*%ff,i64 8
%fn=bitcast i8*%fm to i32*
store i32%eW,i32*%fn,align 4
%fo=getelementptr inbounds i8,i8*%ff,i64 16
%fp=bitcast i8*%fo to i32*
store i32 1,i32*%fp,align 4
br label%eB
fq:
%fr=call i8*@sml_alloc(i32 inreg 20)#0
%fs=getelementptr inbounds i8,i8*%fr,i64 -4
%ft=bitcast i8*%fs to i32*
store i32 1342177296,i32*%ft,align 4
%fu=getelementptr inbounds i8,i8*%fr,i64 12
%fv=bitcast i8*%fu to i32*
store i32 0,i32*%fv,align 1
%fw=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%fx=bitcast i8*%fr to i8**
store i8*%fw,i8**%fx,align 8
%fy=getelementptr inbounds i8,i8*%fr,i64 8
%fz=bitcast i8*%fy to i32*
store i32%eN,i32*%fz,align 4
%fA=getelementptr inbounds i8,i8*%fr,i64 16
%fB=bitcast i8*%fA to i32*
store i32 1,i32*%fB,align 4
%fC=load i8**,i8***%s,align 8
%fD=load i8*,i8**%fC,align 8
store i8*%fD,i8**%f,align 8
store i8*null,i8**%g,align 8
%fE=getelementptr inbounds i8*,i8**%fC,i64 1
%fF=bitcast i8**%fE to i32*
%fG=load i32,i32*%fF,align 4
%fH=sub nsw i32%eN,%fG
%fI=call i8*@sml_alloc(i32 inreg 20)#0
%fJ=getelementptr inbounds i8,i8*%fI,i64 -4
%fK=bitcast i8*%fJ to i32*
store i32 1342177296,i32*%fK,align 4
%fL=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%fM=bitcast i8*%fI to i8**
store i8*%fL,i8**%fM,align 8
%fN=getelementptr inbounds i8,i8*%fI,i64 8
%fO=bitcast i8*%fN to i32*
store i32%fG,i32*%fO,align 4
%fP=getelementptr inbounds i8,i8*%fI,i64 12
%fQ=bitcast i8*%fP to i32*
store i32%fH,i32*%fQ,align 4
%fR=getelementptr inbounds i8,i8*%fI,i64 16
%fS=bitcast i8*%fR to i32*
store i32 1,i32*%fS,align 4
%fT=invoke fastcc i8*@_SMLFN6String9substringE(i8*inreg%fI)
to label%fU unwind label%kQ
fU:
%fV=invoke fastcc i8*@_SMLFN8Filename10fromStringE(i8*inreg%fT)
to label%fW unwind label%kQ
fW:
store i8*%fV,i8**%f,align 8
%fX=call i8*@sml_alloc(i32 inreg 20)#0
%fY=getelementptr inbounds i8,i8*%fX,i64 -4
%fZ=bitcast i8*%fY to i32*
store i32 1342177296,i32*%fZ,align 4
store i8*%fX,i8**%g,align 8
%f0=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%f1=bitcast i8*%fX to i8**
store i8*%f0,i8**%f1,align 8
%f2=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%f3=getelementptr inbounds i8,i8*%fX,i64 8
%f4=bitcast i8*%f3 to i8**
store i8*%f2,i8**%f4,align 8
%f5=getelementptr inbounds i8,i8*%fX,i64 16
%f6=bitcast i8*%f5 to i32*
store i32 3,i32*%f6,align 4
%f7=call i8*@sml_alloc(i32 inreg 12)#0
%f8=getelementptr inbounds i8,i8*%f7,i64 -4
%f9=bitcast i8*%f8 to i32*
store i32 1342177288,i32*%f9,align 4
%ga=load i8*,i8**%g,align 8
br label%j9
gb:
%gc=bitcast i8*%d8 to i8**
%gd=load i8*,i8**%gc,align 8
br label%ge
ge:
%gf=phi i8*[%gT,%gR],[%gd,%gb]
store i8*%gf,i8**%i,align 8
%gg=load atomic i32,i32*@sml_check_flag unordered,align 4
%gh=icmp eq i32%gg,0
%gi=bitcast i8*%gf to i8**
br i1%gh,label%gl,label%gj
gj:
call void@sml_check(i32 inreg%gg)
%gk=load i8**,i8***%q,align 8
br label%gl
gl:
%gm=phi i8**[%gk,%gj],[%gi,%ge]
%gn=load i8*,i8**%gm,align 8
store i8*%gn,i8**%j,align 8
store i8*null,i8**%i,align 8
%go=getelementptr inbounds i8*,i8**%gm,i64 1
%gp=bitcast i8**%go to i32*
%gq=load i32,i32*%gp,align 4
%gr=getelementptr inbounds i8,i8*%gn,i64 -4
%gs=bitcast i8*%gr to i32*
%gt=load i32,i32*%gs,align 4
%gu=and i32%gt,268435455
%gv=add nsw i32%gu,-1
%gw=icmp sgt i32%gv,%gq
br i1%gw,label%gx,label%g4
gx:
%gy=icmp sgt i32%gq,-1
br i1%gy,label%gz,label%gE
gz:
%gA=sext i32%gq to i64
%gB=getelementptr inbounds i8,i8*%gn,i64%gA
%gC=load i8,i8*%gB,align 1
%gD=invoke fastcc i32@_SMLFN4Char7isSpaceE(i8 inreg%gC)
to label%gP unwind label%kM
gE:
store i8*null,i8**%e,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%g,align 8
store i8*null,i8**%h,align 8
store i8*null,i8**%j,align 8
store i8*null,i8**%k,align 8
%gF=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%gF,i8**%d,align 8
%gG=call i8*@sml_alloc(i32 inreg 20)#0
%gH=getelementptr inbounds i8,i8*%gG,i64 -4
%gI=bitcast i8*%gH to i32*
store i32 1342177296,i32*%gI,align 4
%gJ=load i8*,i8**%d,align 8
%gK=bitcast i8*%gG to i8**
store i8*%gJ,i8**%gK,align 8
%gL=getelementptr inbounds i8,i8*%gG,i64 8
%gM=bitcast i8*%gL to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[65x i8]}>,<{[4x i8],i32,[65x i8]}>*@f,i64 0,i32 2,i64 0),i8**%gM,align 8
%gN=getelementptr inbounds i8,i8*%gG,i64 16
%gO=bitcast i8*%gN to i32*
store i32 3,i32*%gO,align 4
store i8*%gG,i8**%d,align 8
br label%kZ
gP:
%gQ=icmp eq i32%gD,0
br i1%gQ,label%g4,label%gR
gR:
%gS=add nsw i32%gq,1
%gT=call i8*@sml_alloc(i32 inreg 20)#0
%gU=getelementptr inbounds i8,i8*%gT,i64 -4
%gV=bitcast i8*%gU to i32*
store i32 1342177296,i32*%gV,align 4
%gW=getelementptr inbounds i8,i8*%gT,i64 12
%gX=bitcast i8*%gW to i32*
store i32 0,i32*%gX,align 1
%gY=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%gZ=bitcast i8*%gT to i8**
store i8*%gY,i8**%gZ,align 8
%g0=getelementptr inbounds i8,i8*%gT,i64 8
%g1=bitcast i8*%g0 to i32*
store i32%gS,i32*%g1,align 4
%g2=getelementptr inbounds i8,i8*%gT,i64 16
%g3=bitcast i8*%g2 to i32*
store i32 1,i32*%g3,align 4
br label%ge
g4:
%g5=call i8*@sml_alloc(i32 inreg 20)#0
%g6=getelementptr inbounds i8,i8*%g5,i64 -4
%g7=bitcast i8*%g6 to i32*
store i32 1342177296,i32*%g7,align 4
%g8=getelementptr inbounds i8,i8*%g5,i64 12
%g9=bitcast i8*%g8 to i32*
store i32 0,i32*%g9,align 1
%ha=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%hb=bitcast i8*%g5 to i8**
store i8*%ha,i8**%hb,align 8
%hc=getelementptr inbounds i8,i8*%g5,i64 8
%hd=bitcast i8*%hc to i32*
store i32%gq,i32*%hd,align 4
%he=getelementptr inbounds i8,i8*%g5,i64 16
%hf=bitcast i8*%he to i32*
store i32 1,i32*%hf,align 4
store i8*%ha,i8**%i,align 8
%hg=getelementptr inbounds i8,i8*%ha,i64 -4
%hh=bitcast i8*%hg to i32*
%hi=load i32,i32*%hh,align 4
%hj=and i32%hi,268435455
%hk=add nsw i32%hj,-1
%hl=icmp sgt i32%hk,%gq
br i1%hl,label%hm,label%hz
hm:
%hn=icmp sgt i32%gq,-1
br i1%hn,label%hA,label%ho
ho:
store i8*null,i8**%e,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%g,align 8
store i8*null,i8**%h,align 8
store i8*null,i8**%i,align 8
store i8*null,i8**%k,align 8
%hp=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%hp,i8**%d,align 8
%hq=call i8*@sml_alloc(i32 inreg 20)#0
%hr=getelementptr inbounds i8,i8*%hq,i64 -4
%hs=bitcast i8*%hr to i32*
store i32 1342177296,i32*%hs,align 4
%ht=load i8*,i8**%d,align 8
%hu=bitcast i8*%hq to i8**
store i8*%ht,i8**%hu,align 8
%hv=getelementptr inbounds i8,i8*%hq,i64 8
%hw=bitcast i8*%hv to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[65x i8]}>,<{[4x i8],i32,[65x i8]}>*@g,i64 0,i32 2,i64 0),i8**%hw,align 8
%hx=getelementptr inbounds i8,i8*%hq,i64 16
%hy=bitcast i8*%hx to i32*
store i32 3,i32*%hy,align 4
store i8*%hq,i8**%d,align 8
br label%kZ
hz:
store i8*null,i8**%i,align 8
br label%h7
hA:
%hB=sext i32%gq to i64
%hC=getelementptr inbounds i8,i8*%ha,i64%hB
%hD=load i8,i8*%hC,align 1
%hE=add nsw i32%gq,1
%hF=call i8*@sml_alloc(i32 inreg 20)#0
%hG=getelementptr inbounds i8,i8*%hF,i64 -4
%hH=bitcast i8*%hG to i32*
store i32 1342177296,i32*%hH,align 4
store i8*%hF,i8**%j,align 8
%hI=getelementptr inbounds i8,i8*%hF,i64 12
%hJ=bitcast i8*%hI to i32*
store i32 0,i32*%hJ,align 1
%hK=load i8*,i8**%i,align 8
%hL=bitcast i8*%hF to i8**
store i8*null,i8**%i,align 8
store i8*%hK,i8**%hL,align 8
%hM=getelementptr inbounds i8,i8*%hF,i64 8
%hN=bitcast i8*%hM to i32*
store i32%hE,i32*%hN,align 4
%hO=getelementptr inbounds i8,i8*%hF,i64 16
%hP=bitcast i8*%hO to i32*
store i32 1,i32*%hP,align 4
%hQ=call i8*@sml_alloc(i32 inreg 20)#0
%hR=getelementptr inbounds i8,i8*%hQ,i64 -4
%hS=bitcast i8*%hR to i32*
store i32 1342177296,i32*%hS,align 4
store i8*%hQ,i8**%i,align 8
%hT=getelementptr inbounds i8,i8*%hQ,i64 1
call void@llvm.memset.p0i8.i32(i8*%hT,i8 0,i32 7,i1 false)
store i8%hD,i8*%hQ,align 1
%hU=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%hV=getelementptr inbounds i8,i8*%hQ,i64 8
%hW=bitcast i8*%hV to i8**
store i8*%hU,i8**%hW,align 8
%hX=getelementptr inbounds i8,i8*%hQ,i64 16
%hY=bitcast i8*%hX to i32*
store i32 2,i32*%hY,align 4
%hZ=call i8*@sml_alloc(i32 inreg 12)#0
%h0=getelementptr inbounds i8,i8*%hZ,i64 -4
%h1=bitcast i8*%h0 to i32*
store i32 1342177288,i32*%h1,align 4
%h2=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%h3=bitcast i8*%hZ to i8**
store i8*%h2,i8**%h3,align 8
%h4=getelementptr inbounds i8,i8*%hZ,i64 8
%h5=bitcast i8*%h4 to i32*
store i32 1,i32*%h5,align 4
%h6=icmp eq i8*%hZ,null
br i1%h6,label%h7,label%ja
h7:
%h8=load i8**,i8***%p,align 8
%h9=load i8*,i8**%h8,align 8
store i8*%h9,i8**%i,align 8
store i8*null,i8**%e,align 8
%ia=getelementptr inbounds i8*,i8**%h8,i64 1
%ib=bitcast i8**%ia to i32*
%ic=load i32,i32*%ib,align 4
%id=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ie=getelementptr inbounds i8,i8*%id,i64 8
%if=bitcast i8*%ie to i32*
%ig=load i32,i32*%if,align 4
%ih=sub nsw i32%ig,%ic
%ii=call i8*@sml_alloc(i32 inreg 20)#0
%ij=getelementptr inbounds i8,i8*%ii,i64 -4
%ik=bitcast i8*%ij to i32*
store i32 1342177296,i32*%ik,align 4
%il=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%im=bitcast i8*%ii to i8**
store i8*%il,i8**%im,align 8
%in=getelementptr inbounds i8,i8*%ii,i64 8
%io=bitcast i8*%in to i32*
store i32%ic,i32*%io,align 4
%ip=getelementptr inbounds i8,i8*%ii,i64 12
%iq=bitcast i8*%ip to i32*
store i32%ih,i32*%iq,align 4
%ir=getelementptr inbounds i8,i8*%ii,i64 16
%is=bitcast i8*%ir to i32*
store i32 1,i32*%is,align 4
%it=invoke fastcc i8*@_SMLFN6String9substringE(i8*inreg%ii)
to label%iu unwind label%kQ
iu:
%iv=invoke fastcc i8*@_SMLFN8Filename10fromStringE(i8*inreg%it)
to label%iw unwind label%kQ
iw:
store i8*%iv,i8**%e,align 8
%ix=load i8**,i8***%s,align 8
%iy=load i8*,i8**%ix,align 8
store i8*%iy,i8**%f,align 8
store i8*null,i8**%g,align 8
%iz=getelementptr inbounds i8*,i8**%ix,i64 1
%iA=bitcast i8**%iz to i32*
%iB=load i32,i32*%iA,align 4
%iC=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%iD=getelementptr inbounds i8,i8*%iC,i64 8
%iE=bitcast i8*%iD to i32*
%iF=load i32,i32*%iE,align 4
%iG=sub nsw i32%iF,%iB
%iH=call i8*@sml_alloc(i32 inreg 20)#0
%iI=getelementptr inbounds i8,i8*%iH,i64 -4
%iJ=bitcast i8*%iI to i32*
store i32 1342177296,i32*%iJ,align 4
%iK=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%iL=bitcast i8*%iH to i8**
store i8*%iK,i8**%iL,align 8
%iM=getelementptr inbounds i8,i8*%iH,i64 8
%iN=bitcast i8*%iM to i32*
store i32%iB,i32*%iN,align 4
%iO=getelementptr inbounds i8,i8*%iH,i64 12
%iP=bitcast i8*%iO to i32*
store i32%iG,i32*%iP,align 4
%iQ=getelementptr inbounds i8,i8*%iH,i64 16
%iR=bitcast i8*%iQ to i32*
store i32 1,i32*%iR,align 4
%iS=invoke fastcc i8*@_SMLFN6String9substringE(i8*inreg%iH)
to label%iT unwind label%kQ
iT:
%iU=invoke fastcc i8*@_SMLFN8Filename10fromStringE(i8*inreg%iS)
to label%iV unwind label%kQ
iV:
store i8*%iU,i8**%f,align 8
%iW=call i8*@sml_alloc(i32 inreg 20)#0
%iX=getelementptr inbounds i8,i8*%iW,i64 -4
%iY=bitcast i8*%iX to i32*
store i32 1342177296,i32*%iY,align 4
store i8*%iW,i8**%g,align 8
%iZ=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%i0=bitcast i8*%iW to i8**
store i8*%iZ,i8**%i0,align 8
%i1=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%i2=getelementptr inbounds i8,i8*%iW,i64 8
%i3=bitcast i8*%i2 to i8**
store i8*%i1,i8**%i3,align 8
%i4=getelementptr inbounds i8,i8*%iW,i64 16
%i5=bitcast i8*%i4 to i32*
store i32 3,i32*%i5,align 4
%i6=call i8*@sml_alloc(i32 inreg 12)#0
%i7=getelementptr inbounds i8,i8*%i6,i64 -4
%i8=bitcast i8*%i7 to i32*
store i32 1342177288,i32*%i8,align 4
%i9=load i8*,i8**%g,align 8
br label%j9
ja:
store i8*null,i8**%d,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%g,align 8
store i8*null,i8**%h,align 8
store i8*null,i8**%k,align 8
%jb=load i8,i8*%h2,align 1
%jc=invoke fastcc i8*@_SMLFN6String3strE(i8 inreg%jb)
to label%jd unwind label%kS
jd:
store i8*%jc,i8**%d,align 8
%je=call i8*@sml_alloc(i32 inreg 20)#0
%jf=getelementptr inbounds i8,i8*%je,i64 -4
%jg=bitcast i8*%jf to i32*
store i32 1342177296,i32*%jg,align 4
%jh=bitcast i8*%je to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[25x i8]}>,<{[4x i8],i32,[25x i8]}>*@h,i64 0,i32 2,i64 0),i8**%jh,align 8
%ji=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%jj=getelementptr inbounds i8,i8*%je,i64 8
%jk=bitcast i8*%jj to i8**
store i8*%ji,i8**%jk,align 8
%jl=getelementptr inbounds i8,i8*%je,i64 16
%jm=bitcast i8*%jl to i32*
store i32 3,i32*%jm,align 4
%jn=invoke fastcc i8*@_SMLFN6String1_ZE(i8*inreg%je)
to label%jo unwind label%kS
jo:
store i8*%jn,i8**%d,align 8
%jp=call i8*@sml_alloc(i32 inreg 20)#0
%jq=bitcast i8*%jp to i32*
%jr=getelementptr inbounds i8,i8*%jp,i64 -4
%js=bitcast i8*%jr to i32*
store i32 1342177296,i32*%js,align 4
%jt=getelementptr inbounds i8,i8*%jp,i64 4
%ju=bitcast i8*%jt to i32*
store i32 0,i32*%ju,align 1
store i32%u,i32*%jq,align 4
%jv=load i8*,i8**%d,align 8
%jw=getelementptr inbounds i8,i8*%jp,i64 8
%jx=bitcast i8*%jw to i8**
store i8*%jv,i8**%jx,align 8
%jy=getelementptr inbounds i8,i8*%jp,i64 16
%jz=bitcast i8*%jy to i32*
store i32 2,i32*%jz,align 4
store i8*%jp,i8**%d,align 8
br label%jA
jA:
%jB=phi i8*[%jp,%jo],[%dP,%dO],[%dr,%dq],[%ci,%ch]
%jC=load atomic i32,i32*@sml_check_flag unordered,align 4
%jD=icmp eq i32%jC,0
br i1%jD,label%jG,label%jE
jE:
call void@sml_check(i32 inreg%jC)
%jF=load i8*,i8**%d,align 8
br label%jG
jG:
%jH=phi i8*[%jF,%jE],[%jB,%jA]
%jI=bitcast i8*%jH to i32*
%jJ=load i32,i32*%jI,align 4
%jK=getelementptr inbounds i8,i8*%jH,i64 8
%jL=bitcast i8*%jK to i8**
%jM=load i8*,i8**%jL,align 8
store i8*%jM,i8**%d,align 8
%jN=call i8*@sml_alloc(i32 inreg 20)#0
%jO=getelementptr inbounds i8,i8*%jN,i64 -4
%jP=bitcast i8*%jO to i32*
store i32 1342177296,i32*%jP,align 4
store i8*%jN,i8**%e,align 8
%jQ=getelementptr inbounds i8,i8*%jN,i64 4
%jR=bitcast i8*%jQ to i32*
store i32 0,i32*%jR,align 1
%jS=bitcast i8*%jN to i32*
store i32%jJ,i32*%jS,align 4
%jT=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%jU=getelementptr inbounds i8,i8*%jN,i64 8
%jV=bitcast i8*%jU to i8**
store i8*%jT,i8**%jV,align 8
%jW=getelementptr inbounds i8,i8*%jN,i64 16
%jX=bitcast i8*%jW to i32*
store i32 2,i32*%jX,align 4
%jY=call i8*@sml_alloc(i32 inreg 28)#0
%jZ=getelementptr inbounds i8,i8*%jY,i64 -4
%j0=bitcast i8*%jZ to i32*
store i32 1342177304,i32*%j0,align 4
%j1=bitcast i8*%jY to i8**
store i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL85,i64 0,i32 2)to i8*),i8**%j1,align 8
%j2=getelementptr inbounds i8,i8*%jY,i64 8
%j3=bitcast i8*%j2 to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[64x i8]}>,<{[4x i8],i32,[64x i8]}>*@e,i64 0,i32 2,i64 0),i8**%j3,align 8
%j4=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%j5=getelementptr inbounds i8,i8*%jY,i64 16
%j6=bitcast i8*%j5 to i8**
store i8*%j4,i8**%j6,align 8
%j7=getelementptr inbounds i8,i8*%jY,i64 24
%j8=bitcast i8*%j7 to i32*
store i32 7,i32*%j8,align 4
store i8*%jY,i8**%d,align 8
br label%kZ
j9:
%ka=phi i8*[%i6,%iV],[%f7,%fW]
%kb=phi i8*[%i9,%iV],[%ga,%fW]
store i8*null,i8**%g,align 8
%kc=bitcast i8*%ka to i8**
store i8*%kb,i8**%kc,align 8
%kd=getelementptr inbounds i8,i8*%ka,i64 8
%ke=bitcast i8*%kd to i32*
store i32 1,i32*%ke,align 4
%kf=icmp eq i8*%ka,null
br i1%kf,label%kg,label%ki
kg:
%kh=add nuw nsw i32%u,1
br label%t
ki:
%kj=bitcast i8*%kb to i8**
%kk=load i8*,i8**%kj,align 8
%kl=getelementptr inbounds i8,i8*%kb,i64 8
%km=bitcast i8*%kl to i8**
%kn=load i8*,i8**%km,align 8
store i8*%kn,i8**%e,align 8
%ko=load i8*,i8**%k,align 8
%kp=getelementptr inbounds i8,i8*%ko,i64 8
%kq=bitcast i8*%kp to i8**
%kr=load i8*,i8**%kq,align 8
store i8*%kr,i8**%g,align 8
%ks=invoke fastcc i8*@_SMLFN8Filename10componentsE(i8*inreg%kk)
to label%kt unwind label%kQ
kt:
store i8*%ks,i8**%f,align 8
%ku=call i8*@sml_alloc(i32 inreg 28)#0
%kv=getelementptr inbounds i8,i8*%ku,i64 -4
%kw=bitcast i8*%kv to i32*
store i32 1342177304,i32*%kw,align 4
%kx=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%ky=bitcast i8*%ku to i8**
store i8*%kx,i8**%ky,align 8
%kz=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%kA=getelementptr inbounds i8,i8*%ku,i64 8
%kB=bitcast i8*%kA to i8**
store i8*%kz,i8**%kB,align 8
%kC=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%kD=getelementptr inbounds i8,i8*%ku,i64 16
%kE=bitcast i8*%kD to i8**
store i8*%kC,i8**%kE,align 8
%kF=getelementptr inbounds i8,i8*%ku,i64 24
%kG=bitcast i8*%kF to i32*
store i32 7,i32*%kG,align 4
%kH=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%kI=invoke fastcc i8*@_SMLLLN11UserFileMap3addE_86(i8*inreg%kH,i8*inreg%ku)
to label%kJ unwind label%kQ
kJ:
store i8*%kI,i8**%d,align 8
br label%kg
kK:
%kL=landingpad{i8*,i8*}
catch i8*null
br label%kU
kM:
%kN=landingpad{i8*,i8*}
catch i8*null
br label%kU
kO:
%kP=landingpad{i8*,i8*}
catch i8*null
br label%kU
kQ:
%kR=landingpad{i8*,i8*}
catch i8*null
br label%kU
kS:
%kT=landingpad{i8*,i8*}
catch i8*null
br label%kU
kU:
%kV=phi{i8*,i8*}[%kL,%kK],[%kN,%kM],[%kP,%kO],[%kR,%kQ],[%kT,%kS]
%kW=extractvalue{i8*,i8*}%kV,1
%kX=bitcast i8*%kW to i8**
%kY=load i8*,i8**%kX,align 8
store i8*null,i8**%j,align 8
store i8*null,i8**%h,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%k,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%g,align 8
store i8*%kY,i8**%d,align 8
br label%kZ
kZ:
%k0=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
call fastcc void@_SMLFN6TextIO7closeInE(i8*inreg%k0)
%k1=call i8*@sml_alloc(i32 inreg 60)#0
%k2=getelementptr inbounds i8,i8*%k1,i64 -4
%k3=bitcast i8*%k2 to i32*
store i32 1342177336,i32*%k3,align 4
%k4=getelementptr inbounds i8,i8*%k1,i64 56
%k5=bitcast i8*%k4 to i32*
store i32 1,i32*%k5,align 4
%k6=load i8*,i8**%d,align 8
%k7=bitcast i8*%k1 to i8**
store i8*%k6,i8**%k7,align 8
call void@sml_raise(i8*inreg%k1)#1
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
%l=tail call fastcc i8*@_SMLLLN11UserFileMap4loadE_105(i8*inreg%k,i8*inreg%h)
ret i8*%l
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
%l=tail call fastcc i8*@_SMLLLN11UserFileMap8fromListE_88(i8*inreg%k,i8*inreg%h)
ret i8*%l
}
define internal fastcc i8*@_SMLLLN11UserFileMap4findE_108(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11UserFileMap4findE(i8*inreg%b)
ret i8*%c
}
declare void@llvm.memset.p0i8.i32(i8*,i8,i32,i1)#0
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
