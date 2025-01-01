@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN3Bug3BugE=external local_unnamed_addr global i8*
@_SMLZN8ListPair14UnequalLengthsE=external local_unnamed_addr global i8*
@_SMLZN9LLVMUtils6ASMEXTE=external local_unnamed_addr global i8*
@_SMLZ5Match=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLLLN8LLVMEmit5mergeE_93 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit5mergeE_131 to void(...)*),i32 -2147483647}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,[64x i8]}><{[4x i8]zeroinitializer,i32 -2147483584,[64x i8]c"src/compiler/compilePhases/llvmemit/main/LLVMEmit.sml:27.6(751)\00"}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLLL7phiArgs_113 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL7phiArgs_132 to void(...)*),i32 -2147483647}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLLL4phis_115 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL4phis_133 to void(...)*),i32 -2147483647}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[66x i8]}><{[4x i8]zeroinitializer,i32 -2147483582,[66x i8]c"src/compiler/compilePhases/llvmemit/main/LLVMEmit.sml:62.54(2258)\00"}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,[16x i8]}><{[4x i8]zeroinitializer,i32 -2147483632,[16x i8]c"completePhiBody\00"}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,[65x i8]}><{[4x i8]zeroinitializer,i32 -2147483583,[65x i8]c"src/compiler/compilePhases/llvmemit/main/LLVMEmit.sml:50.6(1750)\00"}>,align 8
@h=private unnamed_addr constant<{[4x i8],i32,[65x i8]}><{[4x i8]zeroinitializer,i32 -2147483583,[65x i8]c"src/compiler/compilePhases/llvmemit/main/LLVMEmit.sml:89.6(3165)\00"}>,align 8
@i=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c".\00"}>,align 8
@j=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c"w\00"}>,align 8
@k=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8(i32)*@_SMLLL6spaces_124 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL6spaces_135 to void(...)*),i32 -2147483647}>,align 8
@l=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c"\0A\00"}>,align 8
@m=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c" \00"}>,align 8
@n=private unnamed_addr constant<{[4x i8],i32,[66x i8]}><{[4x i8]zeroinitializer,i32 -2147483582,[66x i8]c"src/compiler/compilePhases/llvmemit/main/LLVMEmit.sml:132.6(4406)\00"}>,align 8
@_SML_gvarb79694c2fa396fe4_LLVMEmit=private global<{[4x i8],i32,[1x i8*]}><{[4x i8]zeroinitializer,i32 -1342177272,[1x i8*]zeroinitializer}>,align 8
@o=private unnamed_addr global[2x i64][i64 1,i64 sub(i64 ptrtoint(i8**getelementptr inbounds(<{[4x i8],i32,[1x i8*]}>,<{[4x i8],i32,[1x i8*]}>*@_SML_gvarb79694c2fa396fe4_LLVMEmit,i32 0,i32 2,i32 0)to i64),i64 ptrtoint([2x i64]*@o to i64))]
@_SML_ftabb79694c2fa396fe4_LLVMEmit=external global i8
@p=private unnamed_addr global i8 0
@_SMLZN8LLVMEmit4emitE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[1x i8*]}>,<{[4x i8],i32,[1x i8*]}>*@_SML_gvarb79694c2fa396fe4_LLVMEmit,i32 0,i32 2,i32 0)
declare i32@fclose(i8*)local_unnamed_addr#0
declare i8*@fopen(i8*,i8*)local_unnamed_addr#0
declare i32@fputs(i8*,i8*)local_unnamed_addr#0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_end()local_unnamed_addr#0
declare void@sml_enter()local_unnamed_addr#0
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_leave()local_unnamed_addr#0
declare void@sml_matchcomp_bug()local_unnamed_addr
declare i32@sml_personality(...)#0
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare void@sml_save_exn(i8*inreg)local_unnamed_addr#0
declare void@sml_start(i8*inreg)local_unnamed_addr#0
declare void@sml_write(i8*inreg,i8**inreg,i8*inreg)local_unnamed_addr#0
declare i8*@_SMLFN10CharVector8tabulateE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN13FunLocalLabel3Map4findE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN13FunLocalLabel3Map5emptyE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN13FunLocalLabel3Map9singletonE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN13FunLocalLabel3Map9unionWithE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN16SMLSharp__Runtime9OS__SysErrE(i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List1_VE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List3mapE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List5foldlE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN6LLVMIR14format__programE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN6String1_ZE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN7Pointer6isNullE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN8Filename8toStringE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN8ListPair5mapEqE(i32 inreg,i32 inreg,i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN8TempFile6createE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main00d884c96265bfea_SMLSharp_Runtime()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_mainadbb5309e852b68c_CharVector()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main03d87556ec7f64b2_List()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main7aa263535439ee1c_ListPair()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main1ef93e13728790b1_String()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main15b022b21c7f9f6b_Pointer()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maineaa0aca8fbe4101a_Bug()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maine29d9c3af819282f_Filename()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maine7eca9e7f5c591d9_CodeLabel()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main0a912fe1d4e49644_LLVMIR_ppg()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_mainca0e9aa4897964a8_TempFile()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main66ab07276687d947_LLVMUtils()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load00d884c96265bfea_SMLSharp_Runtime(i8*)local_unnamed_addr
declare void@_SML_loadadbb5309e852b68c_CharVector(i8*)local_unnamed_addr
declare void@_SML_load03d87556ec7f64b2_List(i8*)local_unnamed_addr
declare void@_SML_load7aa263535439ee1c_ListPair(i8*)local_unnamed_addr
declare void@_SML_load1ef93e13728790b1_String(i8*)local_unnamed_addr
declare void@_SML_load15b022b21c7f9f6b_Pointer(i8*)local_unnamed_addr
declare void@_SML_loadeaa0aca8fbe4101a_Bug(i8*)local_unnamed_addr
declare void@_SML_loade29d9c3af819282f_Filename(i8*)local_unnamed_addr
declare void@_SML_loade7eca9e7f5c591d9_CodeLabel(i8*)local_unnamed_addr
declare void@_SML_load0a912fe1d4e49644_LLVMIR_ppg(i8*)local_unnamed_addr
declare void@_SML_loadca0e9aa4897964a8_TempFile(i8*)local_unnamed_addr
declare void@_SML_load66ab07276687d947_LLVMUtils(i8*)local_unnamed_addr
define private void@_SML_tabbb79694c2fa396fe4_LLVMEmit()#3{
unreachable
}
define void@_SML_loadb79694c2fa396fe4_LLVMEmit(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@p,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@p,align 1
tail call void@_SML_load00d884c96265bfea_SMLSharp_Runtime(i8*%a)#0
tail call void@_SML_loadadbb5309e852b68c_CharVector(i8*%a)#0
tail call void@_SML_load03d87556ec7f64b2_List(i8*%a)#0
tail call void@_SML_load7aa263535439ee1c_ListPair(i8*%a)#0
tail call void@_SML_load1ef93e13728790b1_String(i8*%a)#0
tail call void@_SML_load15b022b21c7f9f6b_Pointer(i8*%a)#0
tail call void@_SML_loadeaa0aca8fbe4101a_Bug(i8*%a)#0
tail call void@_SML_loade29d9c3af819282f_Filename(i8*%a)#0
tail call void@_SML_loade7eca9e7f5c591d9_CodeLabel(i8*%a)#0
tail call void@_SML_load0a912fe1d4e49644_LLVMIR_ppg(i8*%a)#0
tail call void@_SML_loadca0e9aa4897964a8_TempFile(i8*%a)#0
tail call void@_SML_load66ab07276687d947_LLVMUtils(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbb79694c2fa396fe4_LLVMEmit,i8*@_SML_ftabb79694c2fa396fe4_LLVMEmit,i8*bitcast([2x i64]*@o to i8*))#0
ret void
}
define void@_SML_mainb79694c2fa396fe4_LLVMEmit()local_unnamed_addr#2 gc"smlsharp"personality i32(...)*@sml_personality{
%a=alloca[3x i8*],align 8
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=load i8,i8*@p,align 1
%e=and i8%d,2
%f=icmp eq i8%e,0
br i1%f,label%h,label%g
g:
ret void
h:
store i8 3,i8*@p,align 1
tail call void@_SML_main00d884c96265bfea_SMLSharp_Runtime()#2
tail call void@_SML_mainadbb5309e852b68c_CharVector()#2
tail call void@_SML_main03d87556ec7f64b2_List()#2
tail call void@_SML_main7aa263535439ee1c_ListPair()#2
tail call void@_SML_main1ef93e13728790b1_String()#2
tail call void@_SML_main15b022b21c7f9f6b_Pointer()#2
tail call void@_SML_maineaa0aca8fbe4101a_Bug()#2
tail call void@_SML_maine29d9c3af819282f_Filename()#2
tail call void@_SML_maine7eca9e7f5c591d9_CodeLabel()#2
tail call void@_SML_main0a912fe1d4e49644_LLVMIR_ppg()#2
tail call void@_SML_mainca0e9aa4897964a8_TempFile()#2
tail call void@_SML_main66ab07276687d947_LLVMUtils()#2
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
%i=bitcast[3x i8*]*%a to i8*
call void@sml_start(i8*inreg%i)#0
%j=load atomic i32,i32*@sml_check_flag unordered,align 4
%k=icmp eq i32%j,0
br i1%k,label%m,label%l
l:
invoke void@sml_check(i32 inreg%j)
to label%m unwind label%ar
m:
%n=invoke fastcc i8*@_SMLFN13FunLocalLabel3Map5emptyE(i32 inreg 1,i32 inreg 8)
to label%o unwind label%ar
o:
store i8*%n,i8**%b,align 8
%p=call i8*@sml_alloc(i32 inreg 12)#0
%q=getelementptr inbounds i8,i8*%p,i64 -4
%r=bitcast i8*%q to i32*
store i32 1342177288,i32*%r,align 4
store i8*%p,i8**%c,align 8
%s=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%t=bitcast i8*%p to i8**
store i8*%s,i8**%t,align 8
%u=getelementptr inbounds i8,i8*%p,i64 8
%v=bitcast i8*%u to i32*
store i32 1,i32*%v,align 4
%w=call i8*@sml_alloc(i32 inreg 28)#0
%x=getelementptr inbounds i8,i8*%w,i64 -4
%y=bitcast i8*%x to i32*
store i32 1342177304,i32*%y,align 4
%z=load i8*,i8**%c,align 8
%A=bitcast i8*%w to i8**
store i8*%z,i8**%A,align 8
%B=getelementptr inbounds i8,i8*%w,i64 8
%C=bitcast i8*%B to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLLN8LLVMEmit10makePhiMapE_95 to void(...)*),void(...)**%C,align 8
%D=getelementptr inbounds i8,i8*%w,i64 16
%E=bitcast i8*%D to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLLN8LLVMEmit10makePhiMapE_95 to void(...)*),void(...)**%E,align 8
%F=getelementptr inbounds i8,i8*%w,i64 24
%G=bitcast i8*%F to i32*
store i32 -2147483647,i32*%G,align 4
%H=call i8*@sml_alloc(i32 inreg 12)#0
%I=getelementptr inbounds i8,i8*%H,i64 -4
%J=bitcast i8*%I to i32*
store i32 1342177288,i32*%J,align 4
store i8*%H,i8**%b,align 8
%K=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%L=bitcast i8*%H to i8**
store i8*%K,i8**%L,align 8
%M=getelementptr inbounds i8,i8*%H,i64 8
%N=bitcast i8*%M to i32*
store i32 1,i32*%N,align 4
%O=call i8*@sml_alloc(i32 inreg 28)#0
%P=getelementptr inbounds i8,i8*%O,i64 -4
%Q=bitcast i8*%P to i32*
store i32 1342177304,i32*%Q,align 4
store i8*%O,i8**%c,align 8
%R=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%S=bitcast i8*%O to i8**
store i8*%R,i8**%S,align 8
%T=getelementptr inbounds i8,i8*%O,i64 8
%U=bitcast i8*%T to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit17completePhiTopdecE_121 to void(...)*),void(...)**%U,align 8
%V=getelementptr inbounds i8,i8*%O,i64 16
%W=bitcast i8*%V to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit17completePhiTopdecE_121 to void(...)*),void(...)**%W,align 8
%X=getelementptr inbounds i8,i8*%O,i64 24
%Y=bitcast i8*%X to i32*
store i32 -2147483647,i32*%Y,align 4
%Z=call i8*@sml_alloc(i32 inreg 12)#0
%aa=getelementptr inbounds i8,i8*%Z,i64 -4
%ab=bitcast i8*%aa to i32*
store i32 1342177288,i32*%ab,align 4
store i8*%Z,i8**%b,align 8
%ac=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ad=bitcast i8*%Z to i8**
store i8*%ac,i8**%ad,align 8
%ae=getelementptr inbounds i8,i8*%Z,i64 8
%af=bitcast i8*%ae to i32*
store i32 1,i32*%af,align 4
%ag=call i8*@sml_alloc(i32 inreg 28)#0
%ah=getelementptr inbounds i8,i8*%ag,i64 -4
%ai=bitcast i8*%ah to i32*
store i32 1342177304,i32*%ai,align 4
%aj=load i8*,i8**%b,align 8
%ak=bitcast i8*%ag to i8**
store i8*%aj,i8**%ak,align 8
%al=getelementptr inbounds i8,i8*%ag,i64 8
%am=bitcast i8*%al to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit4emitE_129 to void(...)*),void(...)**%am,align 8
%an=getelementptr inbounds i8,i8*%ag,i64 16
%ao=bitcast i8*%an to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit4emitE_129 to void(...)*),void(...)**%ao,align 8
%ap=getelementptr inbounds i8,i8*%ag,i64 24
%aq=bitcast i8*%ap to i32*
store i32 -2147483647,i32*%aq,align 4
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[1x i8*]}>,<{[4x i8],i32,[1x i8*]}>*@_SML_gvarb79694c2fa396fe4_LLVMEmit,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[1x i8*]}>,<{[4x i8],i32,[1x i8*]}>*@_SML_gvarb79694c2fa396fe4_LLVMEmit,i64 0,i32 2,i64 0),i8*inreg%ag)#0
call void@sml_end()#0
ret void
ar:
%as=landingpad{i8*,i8*}
cleanup
%at=extractvalue{i8*,i8*}%as,1
call void@sml_save_exn(i8*inreg%at)#0
call void@sml_end()#0
resume{i8*,i8*}%as
}
define internal fastcc i8*@_SMLLLN8LLVMEmit5mergeE_93(i8*inreg%a)#2 gc"smlsharp"{
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
%m=bitcast i8*%k to i8**
%n=load i8*,i8**%m,align 8
store i8*%n,i8**%b,align 8
%o=getelementptr inbounds i8,i8*%k,i64 8
%p=bitcast i8*%o to i8**
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%c,align 8
%r=call fastcc i8*@_SMLFN13FunLocalLabel3Map9unionWithE(i32 inreg 1,i32 inreg 8)
%s=getelementptr inbounds i8,i8*%r,i64 16
%t=bitcast i8*%s to i8*(i8*,i8*)**
%u=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%t,align 8
%v=bitcast i8*%r to i8**
%w=load i8*,i8**%v,align 8
store i8*%w,i8**%e,align 8
%x=call fastcc i8*@_SMLFN8ListPair5mapEqE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%y=getelementptr inbounds i8,i8*%x,i64 16
%z=bitcast i8*%y to i8*(i8*,i8*)**
%A=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%z,align 8
%B=bitcast i8*%x to i8**
%C=load i8*,i8**%B,align 8
store i8*%C,i8**%d,align 8
%D=call fastcc i8*@_SMLFN4List1_VE(i32 inreg 1,i32 inreg 8)
%E=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%F=call fastcc i8*%A(i8*inreg%E,i8*inreg%D)
%G=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%H=call fastcc i8*%u(i8*inreg%G,i8*inreg%F)
%I=getelementptr inbounds i8,i8*%H,i64 16
%J=bitcast i8*%I to i8*(i8*,i8*)**
%K=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%J,align 8
%L=bitcast i8*%H to i8**
%M=load i8*,i8**%L,align 8
store i8*%M,i8**%d,align 8
%N=call i8*@sml_alloc(i32 inreg 20)#0
%O=getelementptr inbounds i8,i8*%N,i64 -4
%P=bitcast i8*%O to i32*
store i32 1342177296,i32*%P,align 4
%Q=load i8*,i8**%b,align 8
%R=bitcast i8*%N to i8**
store i8*%Q,i8**%R,align 8
%S=load i8*,i8**%c,align 8
%T=getelementptr inbounds i8,i8*%N,i64 8
%U=bitcast i8*%T to i8**
store i8*%S,i8**%U,align 8
%V=getelementptr inbounds i8,i8*%N,i64 16
%W=bitcast i8*%V to i32*
store i32 3,i32*%W,align 4
%X=load i8*,i8**%d,align 8
%Y=tail call fastcc i8*%K(i8*inreg%X,i8*inreg%N)
ret i8*%Y
}
define internal fastcc i8*@_SMLLLN8LLVMEmit10makePhiMapE_96(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
%f=getelementptr inbounds i8,i8*%b,i64 8
%g=bitcast i8*%f to i8**
%h=load i8*,i8**%g,align 8
store i8*%h,i8**%c,align 8
%i=bitcast i8*%a to i8**
%j=load i8*,i8**%i,align 8
store i8*%j,i8**%d,align 8
%k=call i8*@sml_alloc(i32 inreg 20)#0
%l=getelementptr inbounds i8,i8*%k,i64 -4
%m=bitcast i8*%l to i32*
store i32 1342177296,i32*%m,align 4
store i8*%k,i8**%e,align 8
%n=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%o=bitcast i8*%k to i8**
store i8*%n,i8**%o,align 8
%p=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%q=getelementptr inbounds i8,i8*%k,i64 8
%r=bitcast i8*%q to i8**
store i8*%p,i8**%r,align 8
%s=getelementptr inbounds i8,i8*%k,i64 16
%t=bitcast i8*%s to i32*
store i32 3,i32*%t,align 4
%u=call i8*@sml_alloc(i32 inreg 20)#0
%v=getelementptr inbounds i8,i8*%u,i64 -4
%w=bitcast i8*%v to i32*
store i32 1342177296,i32*%w,align 4
%x=load i8*,i8**%e,align 8
%y=bitcast i8*%u to i8**
store i8*%x,i8**%y,align 8
%z=getelementptr inbounds i8,i8*%u,i64 8
%A=bitcast i8*%z to i8**
store i8*null,i8**%A,align 8
%B=getelementptr inbounds i8,i8*%u,i64 16
%C=bitcast i8*%B to i32*
store i32 3,i32*%C,align 4
ret i8*%u
}
define internal fastcc i8*@_SMLLLN8LLVMEmit10makePhiMapE_97(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
%f=getelementptr inbounds i8,i8*%b,i64 8
%g=bitcast i8*%f to i8**
%h=load i8*,i8**%g,align 8
store i8*%h,i8**%c,align 8
%i=bitcast i8*%a to i8**
%j=load i8*,i8**%i,align 8
store i8*%j,i8**%d,align 8
%k=call i8*@sml_alloc(i32 inreg 20)#0
%l=getelementptr inbounds i8,i8*%k,i64 -4
%m=bitcast i8*%l to i32*
store i32 1342177296,i32*%m,align 4
store i8*%k,i8**%e,align 8
%n=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%o=bitcast i8*%k to i8**
store i8*%n,i8**%o,align 8
%p=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%q=getelementptr inbounds i8,i8*%k,i64 8
%r=bitcast i8*%q to i8**
store i8*%p,i8**%r,align 8
%s=getelementptr inbounds i8,i8*%k,i64 16
%t=bitcast i8*%s to i32*
store i32 3,i32*%t,align 4
%u=call i8*@sml_alloc(i32 inreg 20)#0
%v=getelementptr inbounds i8,i8*%u,i64 -4
%w=bitcast i8*%v to i32*
store i32 1342177296,i32*%w,align 4
%x=load i8*,i8**%e,align 8
%y=bitcast i8*%u to i8**
store i8*%x,i8**%y,align 8
%z=getelementptr inbounds i8,i8*%u,i64 8
%A=bitcast i8*%z to i8**
store i8*null,i8**%A,align 8
%B=getelementptr inbounds i8,i8*%u,i64 16
%C=bitcast i8*%B to i32*
store i32 3,i32*%C,align 4
ret i8*%u
}
define internal fastcc i8*@_SMLLLN8LLVMEmit10makePhiMapE_98(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
%f=getelementptr inbounds i8,i8*%b,i64 8
%g=bitcast i8*%f to i8**
%h=load i8*,i8**%g,align 8
store i8*%h,i8**%c,align 8
%i=bitcast i8*%a to i8**
%j=load i8*,i8**%i,align 8
store i8*%j,i8**%d,align 8
%k=call i8*@sml_alloc(i32 inreg 20)#0
%l=getelementptr inbounds i8,i8*%k,i64 -4
%m=bitcast i8*%l to i32*
store i32 1342177296,i32*%m,align 4
store i8*%k,i8**%e,align 8
%n=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%o=bitcast i8*%k to i8**
store i8*%n,i8**%o,align 8
%p=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%q=getelementptr inbounds i8,i8*%k,i64 8
%r=bitcast i8*%q to i8**
store i8*%p,i8**%r,align 8
%s=getelementptr inbounds i8,i8*%k,i64 16
%t=bitcast i8*%s to i32*
store i32 3,i32*%t,align 4
%u=call i8*@sml_alloc(i32 inreg 20)#0
%v=getelementptr inbounds i8,i8*%u,i64 -4
%w=bitcast i8*%v to i32*
store i32 1342177296,i32*%w,align 4
%x=load i8*,i8**%e,align 8
%y=bitcast i8*%u to i8**
store i8*%x,i8**%y,align 8
%z=getelementptr inbounds i8,i8*%u,i64 8
%A=bitcast i8*%z to i8**
store i8*null,i8**%A,align 8
%B=getelementptr inbounds i8,i8*%u,i64 16
%C=bitcast i8*%B to i32*
store i32 3,i32*%C,align 4
ret i8*%u
}
define internal fastcc i8*@_SMLLLN8LLVMEmit10makePhiMapE_99(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
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
%h=call i8*@sml_alloc(i32 inreg 20)#0
%i=getelementptr inbounds i8,i8*%h,i64 -4
%j=bitcast i8*%i to i32*
store i32 1342177296,i32*%j,align 4
store i8*%h,i8**%e,align 8
%k=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%l=bitcast i8*%h to i8**
store i8*%k,i8**%l,align 8
%m=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%n=getelementptr inbounds i8,i8*%h,i64 8
%o=bitcast i8*%n to i8**
store i8*%m,i8**%o,align 8
%p=getelementptr inbounds i8,i8*%h,i64 16
%q=bitcast i8*%p to i32*
store i32 3,i32*%q,align 4
%r=call i8*@sml_alloc(i32 inreg 20)#0
%s=getelementptr inbounds i8,i8*%r,i64 -4
%t=bitcast i8*%s to i32*
store i32 1342177296,i32*%t,align 4
%u=load i8*,i8**%e,align 8
%v=bitcast i8*%r to i8**
store i8*%u,i8**%v,align 8
%w=getelementptr inbounds i8,i8*%r,i64 8
%x=bitcast i8*%w to i8**
store i8*null,i8**%x,align 8
%y=getelementptr inbounds i8,i8*%r,i64 16
%z=bitcast i8*%y to i32*
store i32 3,i32*%z,align 4
ret i8*%r
}
define internal fastcc i8*@_SMLLLN8LLVMEmit10makePhiMapE_100(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
%f=getelementptr inbounds i8,i8*%b,i64 8
%g=bitcast i8*%f to i8**
%h=load i8*,i8**%g,align 8
store i8*%h,i8**%c,align 8
%i=bitcast i8*%a to i8**
%j=load i8*,i8**%i,align 8
store i8*%j,i8**%d,align 8
%k=call i8*@sml_alloc(i32 inreg 20)#0
%l=getelementptr inbounds i8,i8*%k,i64 -4
%m=bitcast i8*%l to i32*
store i32 1342177296,i32*%m,align 4
store i8*%k,i8**%e,align 8
%n=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%o=bitcast i8*%k to i8**
store i8*%n,i8**%o,align 8
%p=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%q=getelementptr inbounds i8,i8*%k,i64 8
%r=bitcast i8*%q to i8**
store i8*%p,i8**%r,align 8
%s=getelementptr inbounds i8,i8*%k,i64 16
%t=bitcast i8*%s to i32*
store i32 3,i32*%t,align 4
%u=call i8*@sml_alloc(i32 inreg 20)#0
%v=getelementptr inbounds i8,i8*%u,i64 -4
%w=bitcast i8*%v to i32*
store i32 1342177296,i32*%w,align 4
%x=load i8*,i8**%e,align 8
%y=bitcast i8*%u to i8**
store i8*%x,i8**%y,align 8
%z=getelementptr inbounds i8,i8*%u,i64 8
%A=bitcast i8*%z to i8**
store i8*null,i8**%A,align 8
%B=getelementptr inbounds i8,i8*%u,i64 16
%C=bitcast i8*%B to i32*
store i32 3,i32*%C,align 4
ret i8*%u
}
define internal fastcc i8*@_SMLLLN8LLVMEmit10makePhiMapE_101(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
%f=getelementptr inbounds i8,i8*%b,i64 8
%g=bitcast i8*%f to i8**
%h=load i8*,i8**%g,align 8
store i8*%h,i8**%c,align 8
%i=bitcast i8*%a to i8**
%j=load i8*,i8**%i,align 8
store i8*%j,i8**%d,align 8
%k=call i8*@sml_alloc(i32 inreg 20)#0
%l=getelementptr inbounds i8,i8*%k,i64 -4
%m=bitcast i8*%l to i32*
store i32 1342177296,i32*%m,align 4
store i8*%k,i8**%e,align 8
%n=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%o=bitcast i8*%k to i8**
store i8*%n,i8**%o,align 8
%p=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%q=getelementptr inbounds i8,i8*%k,i64 8
%r=bitcast i8*%q to i8**
store i8*%p,i8**%r,align 8
%s=getelementptr inbounds i8,i8*%k,i64 16
%t=bitcast i8*%s to i32*
store i32 3,i32*%t,align 4
%u=call i8*@sml_alloc(i32 inreg 20)#0
%v=getelementptr inbounds i8,i8*%u,i64 -4
%w=bitcast i8*%v to i32*
store i32 1342177296,i32*%w,align 4
%x=load i8*,i8**%e,align 8
%y=bitcast i8*%u to i8**
store i8*%x,i8**%y,align 8
%z=getelementptr inbounds i8,i8*%u,i64 8
%A=bitcast i8*%z to i8**
store i8*null,i8**%A,align 8
%B=getelementptr inbounds i8,i8*%u,i64 16
%C=bitcast i8*%B to i32*
store i32 3,i32*%C,align 4
ret i8*%u
}
define internal fastcc i8*@_SMLLLN8LLVMEmit10makePhiMapE_102(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
store i8*%a,i8**%e,align 8
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
%p=getelementptr inbounds i8,i8*%n,i64 8
%q=bitcast i8*%p to i8**
%r=load i8*,i8**%q,align 8
%s=bitcast i8*%r to i8**
%t=load i8*,i8**%s,align 8
store i8*%t,i8**%c,align 8
%u=getelementptr inbounds i8,i8*%r,i64 8
%v=bitcast i8*%u to i8**
%w=load i8*,i8**%v,align 8
store i8*%w,i8**%d,align 8
%x=call fastcc i8*@_SMLFN13FunLocalLabel3Map9singletonE(i32 inreg 1,i32 inreg 8)
%y=getelementptr inbounds i8,i8*%x,i64 16
%z=bitcast i8*%y to i8*(i8*,i8*)**
%A=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%z,align 8
%B=bitcast i8*%x to i8**
%C=load i8*,i8**%B,align 8
store i8*%C,i8**%g,align 8
%D=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%E=getelementptr inbounds i8,i8*%D,i64 16
%F=bitcast i8*%E to i8*(i8*,i8*)**
%G=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%F,align 8
%H=bitcast i8*%D to i8**
%I=load i8*,i8**%H,align 8
store i8*%I,i8**%f,align 8
%J=bitcast i8**%e to i8***
%K=load i8**,i8***%J,align 8
%L=load i8*,i8**%K,align 8
store i8*%L,i8**%e,align 8
%M=call i8*@sml_alloc(i32 inreg 12)#0
%N=getelementptr inbounds i8,i8*%M,i64 -4
%O=bitcast i8*%N to i32*
store i32 1342177288,i32*%O,align 4
store i8*%M,i8**%h,align 8
%P=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%Q=bitcast i8*%M to i8**
store i8*%P,i8**%Q,align 8
%R=getelementptr inbounds i8,i8*%M,i64 8
%S=bitcast i8*%R to i32*
store i32 1,i32*%S,align 4
%T=call i8*@sml_alloc(i32 inreg 28)#0
%U=getelementptr inbounds i8,i8*%T,i64 -4
%V=bitcast i8*%U to i32*
store i32 1342177304,i32*%V,align 4
%W=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%X=bitcast i8*%T to i8**
store i8*%W,i8**%X,align 8
%Y=getelementptr inbounds i8,i8*%T,i64 8
%Z=bitcast i8*%Y to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit10makePhiMapE_101 to void(...)*),void(...)**%Z,align 8
%aa=getelementptr inbounds i8,i8*%T,i64 16
%ab=bitcast i8*%aa to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit10makePhiMapE_101 to void(...)*),void(...)**%ab,align 8
%ac=getelementptr inbounds i8,i8*%T,i64 24
%ad=bitcast i8*%ac to i32*
store i32 -2147483647,i32*%ad,align 4
%ae=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%af=call fastcc i8*%G(i8*inreg%ae,i8*inreg%T)
%ag=getelementptr inbounds i8,i8*%af,i64 16
%ah=bitcast i8*%ag to i8*(i8*,i8*)**
%ai=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ah,align 8
%aj=bitcast i8*%af to i8**
%ak=load i8*,i8**%aj,align 8
%al=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%am=call fastcc i8*%ai(i8*inreg%ak,i8*inreg%al)
store i8*%am,i8**%d,align 8
%an=call i8*@sml_alloc(i32 inreg 20)#0
%ao=getelementptr inbounds i8,i8*%an,i64 -4
%ap=bitcast i8*%ao to i32*
store i32 1342177296,i32*%ap,align 4
%aq=load i8*,i8**%c,align 8
%ar=bitcast i8*%an to i8**
store i8*%aq,i8**%ar,align 8
%as=load i8*,i8**%d,align 8
%at=getelementptr inbounds i8,i8*%an,i64 8
%au=bitcast i8*%at to i8**
store i8*%as,i8**%au,align 8
%av=getelementptr inbounds i8,i8*%an,i64 16
%aw=bitcast i8*%av to i32*
store i32 3,i32*%aw,align 4
%ax=load i8*,i8**%g,align 8
%ay=tail call fastcc i8*%A(i8*inreg%ax,i8*inreg%an)
ret i8*%ay
}
define internal fastcc i8*@_SMLLLN8LLVMEmit10makePhiMapE_95(i8*inreg%a,i8*inreg%b,i8*inreg%c)#2 gc"smlsharp"{
r:
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
%k=alloca i8*,align 8
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
call void@llvm.gcroot(i8**%k,i8*null)#0
store i8*%a,i8**%g,align 8
store i8*%b,i8**%d,align 8
store i8*%c,i8**%e,align 8
%l=load atomic i32,i32*@sml_check_flag unordered,align 4
%m=icmp eq i32%l,0
br i1%m,label%p,label%n
n:
call void@sml_check(i32 inreg%l)
%o=load i8*,i8**%e,align 8
br label%p
p:
%q=phi i8*[%o,%n],[%c,%r]
store i8*null,i8**%e,align 8
%s=getelementptr inbounds i8,i8*%q,i64 8
%t=bitcast i8*%s to i8**
%u=load i8*,i8**%t,align 8
%v=bitcast i8*%u to i32*
%w=load i32,i32*%v,align 4
switch i32%w,label%x[
i32 0,label%h2
i32 4,label%g0
i32 6,label%gW
i32 7,label%gS
i32 1,label%fU
i32 2,label%do
i32 3,label%b2
i32 5,label%bY
i32 8,label%T
i32 9,label%P
]
x:
store i8*null,i8**%g,align 8
call void@sml_matchcomp_bug()
%y=load i8*,i8**@_SMLZ5Match,align 8
store i8*%y,i8**%d,align 8
%z=call i8*@sml_alloc(i32 inreg 20)#0
%A=getelementptr inbounds i8,i8*%z,i64 -4
%B=bitcast i8*%A to i32*
store i32 1342177296,i32*%B,align 4
store i8*%z,i8**%e,align 8
%C=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%D=bitcast i8*%z to i8**
store i8*%C,i8**%D,align 8
%E=getelementptr inbounds i8,i8*%z,i64 8
%F=bitcast i8*%E to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[64x i8]}>,<{[4x i8],i32,[64x i8]}>*@b,i64 0,i32 2,i64 0),i8**%F,align 8
%G=getelementptr inbounds i8,i8*%z,i64 16
%H=bitcast i8*%G to i32*
store i32 3,i32*%H,align 4
%I=call i8*@sml_alloc(i32 inreg 60)#0
%J=getelementptr inbounds i8,i8*%I,i64 -4
%K=bitcast i8*%J to i32*
store i32 1342177336,i32*%K,align 4
%L=getelementptr inbounds i8,i8*%I,i64 56
%M=bitcast i8*%L to i32*
store i32 1,i32*%M,align 4
%N=load i8*,i8**%e,align 8
%O=bitcast i8*%I to i8**
store i8*%N,i8**%O,align 8
call void@sml_raise(i8*inreg%I)#1
unreachable
P:
%Q=bitcast i8**%g to i8***
%R=load i8**,i8***%Q,align 8
%S=load i8*,i8**%R,align 8
ret i8*%S
T:
store i8*null,i8**%g,align 8
%U=getelementptr inbounds i8,i8*%u,i64 8
%V=bitcast i8*%U to i8**
%W=load i8*,i8**%V,align 8
%X=bitcast i8*%W to i8**
%Y=load i8*,i8**%X,align 8
store i8*%Y,i8**%e,align 8
%Z=getelementptr inbounds i8,i8*%W,i64 8
%aa=bitcast i8*%Z to i8**
%ab=load i8*,i8**%aa,align 8
store i8*%ab,i8**%f,align 8
%ac=call fastcc i8*@_SMLFN4List5foldlE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%ad=getelementptr inbounds i8,i8*%ac,i64 16
%ae=bitcast i8*%ad to i8*(i8*,i8*)**
%af=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ae,align 8
%ag=bitcast i8*%ac to i8**
%ah=load i8*,i8**%ag,align 8
%ai=call fastcc i8*%af(i8*inreg%ah,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*))
%aj=bitcast i8**%f to i8***
%ak=load i8**,i8***%aj,align 8
%al=load i8*,i8**%ak,align 8
store i8*%al,i8**%g,align 8
%am=getelementptr inbounds i8*,i8**%ak,i64 1
%an=load i8*,i8**%am,align 8
store i8*%an,i8**%f,align 8
%ao=getelementptr inbounds i8,i8*%ai,i64 16
%ap=bitcast i8*%ao to i8*(i8*,i8*)**
%aq=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ap,align 8
%ar=bitcast i8*%ai to i8**
%as=load i8*,i8**%ar,align 8
store i8*%as,i8**%j,align 8
%at=call fastcc i8*@_SMLFN13FunLocalLabel3Map9singletonE(i32 inreg 1,i32 inreg 8)
%au=getelementptr inbounds i8,i8*%at,i64 16
%av=bitcast i8*%au to i8*(i8*,i8*)**
%aw=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%av,align 8
%ax=bitcast i8*%at to i8**
%ay=load i8*,i8**%ax,align 8
store i8*%ay,i8**%i,align 8
%az=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%aA=getelementptr inbounds i8,i8*%az,i64 16
%aB=bitcast i8*%aA to i8*(i8*,i8*)**
%aC=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aB,align 8
%aD=bitcast i8*%az to i8**
%aE=load i8*,i8**%aD,align 8
store i8*%aE,i8**%h,align 8
%aF=call i8*@sml_alloc(i32 inreg 12)#0
%aG=getelementptr inbounds i8,i8*%aF,i64 -4
%aH=bitcast i8*%aG to i32*
store i32 1342177288,i32*%aH,align 4
store i8*%aF,i8**%k,align 8
%aI=load i8*,i8**%d,align 8
%aJ=bitcast i8*%aF to i8**
store i8*%aI,i8**%aJ,align 8
%aK=getelementptr inbounds i8,i8*%aF,i64 8
%aL=bitcast i8*%aK to i32*
store i32 1,i32*%aL,align 4
%aM=call i8*@sml_alloc(i32 inreg 28)#0
%aN=getelementptr inbounds i8,i8*%aM,i64 -4
%aO=bitcast i8*%aN to i32*
store i32 1342177304,i32*%aO,align 4
%aP=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
%aQ=bitcast i8*%aM to i8**
store i8*%aP,i8**%aQ,align 8
%aR=getelementptr inbounds i8,i8*%aM,i64 8
%aS=bitcast i8*%aR to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit10makePhiMapE_100 to void(...)*),void(...)**%aS,align 8
%aT=getelementptr inbounds i8,i8*%aM,i64 16
%aU=bitcast i8*%aT to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit10makePhiMapE_100 to void(...)*),void(...)**%aU,align 8
%aV=getelementptr inbounds i8,i8*%aM,i64 24
%aW=bitcast i8*%aV to i32*
store i32 -2147483647,i32*%aW,align 4
%aX=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%aY=call fastcc i8*%aC(i8*inreg%aX,i8*inreg%aM)
%aZ=getelementptr inbounds i8,i8*%aY,i64 16
%a0=bitcast i8*%aZ to i8*(i8*,i8*)**
%a1=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%a0,align 8
%a2=bitcast i8*%aY to i8**
%a3=load i8*,i8**%a2,align 8
%a4=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%a5=call fastcc i8*%a1(i8*inreg%a3,i8*inreg%a4)
store i8*%a5,i8**%f,align 8
%a6=call i8*@sml_alloc(i32 inreg 20)#0
%a7=getelementptr inbounds i8,i8*%a6,i64 -4
%a8=bitcast i8*%a7 to i32*
store i32 1342177296,i32*%a8,align 4
%a9=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%ba=bitcast i8*%a6 to i8**
store i8*%a9,i8**%ba,align 8
%bb=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bc=getelementptr inbounds i8,i8*%a6,i64 8
%bd=bitcast i8*%bc to i8**
store i8*%bb,i8**%bd,align 8
%be=getelementptr inbounds i8,i8*%a6,i64 16
%bf=bitcast i8*%be to i32*
store i32 3,i32*%bf,align 4
%bg=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%bh=call fastcc i8*%aw(i8*inreg%bg,i8*inreg%a6)
%bi=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%bj=call fastcc i8*%aq(i8*inreg%bi,i8*inreg%bh)
%bk=getelementptr inbounds i8,i8*%bj,i64 16
%bl=bitcast i8*%bk to i8*(i8*,i8*)**
%bm=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bl,align 8
%bn=bitcast i8*%bj to i8**
%bo=load i8*,i8**%bn,align 8
store i8*%bo,i8**%g,align 8
%bp=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%bq=getelementptr inbounds i8,i8*%bp,i64 16
%br=bitcast i8*%bq to i8*(i8*,i8*)**
%bs=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%br,align 8
%bt=bitcast i8*%bp to i8**
%bu=load i8*,i8**%bt,align 8
store i8*%bu,i8**%f,align 8
%bv=call i8*@sml_alloc(i32 inreg 12)#0
%bw=getelementptr inbounds i8,i8*%bv,i64 -4
%bx=bitcast i8*%bw to i32*
store i32 1342177288,i32*%bx,align 4
store i8*%bv,i8**%h,align 8
%by=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bz=bitcast i8*%bv to i8**
store i8*%by,i8**%bz,align 8
%bA=getelementptr inbounds i8,i8*%bv,i64 8
%bB=bitcast i8*%bA to i32*
store i32 1,i32*%bB,align 4
%bC=call i8*@sml_alloc(i32 inreg 28)#0
%bD=getelementptr inbounds i8,i8*%bC,i64 -4
%bE=bitcast i8*%bD to i32*
store i32 1342177304,i32*%bE,align 4
%bF=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%bG=bitcast i8*%bC to i8**
store i8*%bF,i8**%bG,align 8
%bH=getelementptr inbounds i8,i8*%bC,i64 8
%bI=bitcast i8*%bH to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit10makePhiMapE_102 to void(...)*),void(...)**%bI,align 8
%bJ=getelementptr inbounds i8,i8*%bC,i64 16
%bK=bitcast i8*%bJ to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit10makePhiMapE_102 to void(...)*),void(...)**%bK,align 8
%bL=getelementptr inbounds i8,i8*%bC,i64 24
%bM=bitcast i8*%bL to i32*
store i32 -2147483647,i32*%bM,align 4
%bN=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bO=call fastcc i8*%bs(i8*inreg%bN,i8*inreg%bC)
%bP=getelementptr inbounds i8,i8*%bO,i64 16
%bQ=bitcast i8*%bP to i8*(i8*,i8*)**
%bR=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bQ,align 8
%bS=bitcast i8*%bO to i8**
%bT=load i8*,i8**%bS,align 8
%bU=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bV=call fastcc i8*%bR(i8*inreg%bT,i8*inreg%bU)
%bW=load i8*,i8**%g,align 8
%bX=tail call fastcc i8*%bm(i8*inreg%bW,i8*inreg%bV)
ret i8*%bX
bY:
%bZ=bitcast i8**%g to i8***
%b0=load i8**,i8***%bZ,align 8
%b1=load i8*,i8**%b0,align 8
ret i8*%b1
b2:
store i8*null,i8**%g,align 8
%b3=getelementptr inbounds i8,i8*%u,i64 8
%b4=bitcast i8*%b3 to i8**
%b5=load i8*,i8**%b4,align 8
%b6=getelementptr inbounds i8,i8*%b5,i64 32
%b7=bitcast i8*%b6 to i8**
%b8=load i8*,i8**%b7,align 8
%b9=getelementptr inbounds i8,i8*%b5,i64 48
%ca=bitcast i8*%b9 to i8**
%cb=load i8*,i8**%ca,align 8
store i8*%cb,i8**%e,align 8
%cc=icmp eq i8*%b8,null
br i1%cc,label%cx,label%cd
cd:
%ce=bitcast i8*%b8 to i32*
%cf=load i32,i32*%ce,align 4
%cg=call i8*@sml_alloc(i32 inreg 12)#0
%ch=bitcast i8*%cg to i32*
%ci=getelementptr inbounds i8,i8*%cg,i64 -4
%cj=bitcast i8*%ci to i32*
store i32 1342177288,i32*%cj,align 4
store i8*%cg,i8**%f,align 8
store i32 1,i32*%ch,align 4
%ck=getelementptr inbounds i8,i8*%cg,i64 4
%cl=bitcast i8*%ck to i32*
store i32%cf,i32*%cl,align 4
%cm=getelementptr inbounds i8,i8*%cg,i64 8
%cn=bitcast i8*%cm to i32*
store i32 0,i32*%cn,align 4
%co=call i8*@sml_alloc(i32 inreg 20)#0
%cp=getelementptr inbounds i8,i8*%co,i64 -4
%cq=bitcast i8*%cp to i32*
store i32 1342177296,i32*%cq,align 4
%cr=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%cs=bitcast i8*%co to i8**
store i8*%cr,i8**%cs,align 8
%ct=getelementptr inbounds i8,i8*%co,i64 8
%cu=bitcast i8*%ct to i8**
store i8*null,i8**%cu,align 8
%cv=getelementptr inbounds i8,i8*%co,i64 16
%cw=bitcast i8*%cv to i32*
store i32 3,i32*%cw,align 4
br label%cx
cx:
%cy=phi i8*[%co,%cd],[null,%b2]
store i8*%cy,i8**%f,align 8
%cz=call fastcc i8*@_SMLFN13FunLocalLabel3Map9singletonE(i32 inreg 1,i32 inreg 8)
%cA=getelementptr inbounds i8,i8*%cz,i64 16
%cB=bitcast i8*%cA to i8*(i8*,i8*)**
%cC=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%cB,align 8
%cD=bitcast i8*%cz to i8**
%cE=load i8*,i8**%cD,align 8
store i8*%cE,i8**%h,align 8
%cF=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%cG=getelementptr inbounds i8,i8*%cF,i64 16
%cH=bitcast i8*%cG to i8*(i8*,i8*)**
%cI=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%cH,align 8
%cJ=bitcast i8*%cF to i8**
%cK=load i8*,i8**%cJ,align 8
store i8*%cK,i8**%g,align 8
%cL=call i8*@sml_alloc(i32 inreg 12)#0
%cM=getelementptr inbounds i8,i8*%cL,i64 -4
%cN=bitcast i8*%cM to i32*
store i32 1342177288,i32*%cN,align 4
store i8*%cL,i8**%i,align 8
%cO=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%cP=bitcast i8*%cL to i8**
store i8*%cO,i8**%cP,align 8
%cQ=getelementptr inbounds i8,i8*%cL,i64 8
%cR=bitcast i8*%cQ to i32*
store i32 1,i32*%cR,align 4
%cS=call i8*@sml_alloc(i32 inreg 28)#0
%cT=getelementptr inbounds i8,i8*%cS,i64 -4
%cU=bitcast i8*%cT to i32*
store i32 1342177304,i32*%cU,align 4
%cV=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%cW=bitcast i8*%cS to i8**
store i8*%cV,i8**%cW,align 8
%cX=getelementptr inbounds i8,i8*%cS,i64 8
%cY=bitcast i8*%cX to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit10makePhiMapE_99 to void(...)*),void(...)**%cY,align 8
%cZ=getelementptr inbounds i8,i8*%cS,i64 16
%c0=bitcast i8*%cZ to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit10makePhiMapE_99 to void(...)*),void(...)**%c0,align 8
%c1=getelementptr inbounds i8,i8*%cS,i64 24
%c2=bitcast i8*%c1 to i32*
store i32 -2147483647,i32*%c2,align 4
%c3=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%c4=call fastcc i8*%cI(i8*inreg%c3,i8*inreg%cS)
%c5=getelementptr inbounds i8,i8*%c4,i64 16
%c6=bitcast i8*%c5 to i8*(i8*,i8*)**
%c7=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%c6,align 8
%c8=bitcast i8*%c4 to i8**
%c9=load i8*,i8**%c8,align 8
%da=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%db=call fastcc i8*%c7(i8*inreg%c9,i8*inreg%da)
store i8*%db,i8**%d,align 8
%dc=call i8*@sml_alloc(i32 inreg 20)#0
%dd=getelementptr inbounds i8,i8*%dc,i64 -4
%de=bitcast i8*%dd to i32*
store i32 1342177296,i32*%de,align 4
%df=load i8*,i8**%e,align 8
%dg=bitcast i8*%dc to i8**
store i8*%df,i8**%dg,align 8
%dh=load i8*,i8**%d,align 8
%di=getelementptr inbounds i8,i8*%dc,i64 8
%dj=bitcast i8*%di to i8**
store i8*%dh,i8**%dj,align 8
%dk=getelementptr inbounds i8,i8*%dc,i64 16
%dl=bitcast i8*%dk to i32*
store i32 3,i32*%dl,align 4
%dm=load i8*,i8**%h,align 8
%dn=tail call fastcc i8*%cC(i8*inreg%dm,i8*inreg%dc)
ret i8*%dn
do:
%dp=getelementptr inbounds i8,i8*%u,i64 8
%dq=bitcast i8*%dp to i8**
%dr=load i8*,i8**%dq,align 8
%ds=getelementptr inbounds i8,i8*%dr,i64 8
%dt=bitcast i8*%ds to i8**
%du=load i8*,i8**%dt,align 8
%dv=getelementptr inbounds i8,i8*%dr,i64 16
%dw=bitcast i8*%dv to i8**
%dx=load i8*,i8**%dw,align 8
store i8*%dx,i8**%e,align 8
%dy=bitcast i8*%du to i8**
%dz=load i8*,i8**%dy,align 8
store i8*%dz,i8**%f,align 8
%dA=getelementptr inbounds i8,i8*%du,i64 8
%dB=bitcast i8*%dA to i8**
%dC=load i8*,i8**%dB,align 8
store i8*%dC,i8**%g,align 8
%dD=call fastcc i8*@_SMLFN13FunLocalLabel3Map9singletonE(i32 inreg 1,i32 inreg 8)
%dE=getelementptr inbounds i8,i8*%dD,i64 16
%dF=bitcast i8*%dE to i8*(i8*,i8*)**
%dG=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%dF,align 8
%dH=bitcast i8*%dD to i8**
%dI=load i8*,i8**%dH,align 8
store i8*%dI,i8**%i,align 8
%dJ=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%dK=getelementptr inbounds i8,i8*%dJ,i64 16
%dL=bitcast i8*%dK to i8*(i8*,i8*)**
%dM=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%dL,align 8
%dN=bitcast i8*%dJ to i8**
%dO=load i8*,i8**%dN,align 8
store i8*%dO,i8**%h,align 8
%dP=call i8*@sml_alloc(i32 inreg 12)#0
%dQ=getelementptr inbounds i8,i8*%dP,i64 -4
%dR=bitcast i8*%dQ to i32*
store i32 1342177288,i32*%dR,align 4
store i8*%dP,i8**%j,align 8
%dS=load i8*,i8**%d,align 8
%dT=bitcast i8*%dP to i8**
store i8*%dS,i8**%dT,align 8
%dU=getelementptr inbounds i8,i8*%dP,i64 8
%dV=bitcast i8*%dU to i32*
store i32 1,i32*%dV,align 4
%dW=call i8*@sml_alloc(i32 inreg 28)#0
%dX=getelementptr inbounds i8,i8*%dW,i64 -4
%dY=bitcast i8*%dX to i32*
store i32 1342177304,i32*%dY,align 4
%dZ=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%d0=bitcast i8*%dW to i8**
store i8*%dZ,i8**%d0,align 8
%d1=getelementptr inbounds i8,i8*%dW,i64 8
%d2=bitcast i8*%d1 to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit10makePhiMapE_97 to void(...)*),void(...)**%d2,align 8
%d3=getelementptr inbounds i8,i8*%dW,i64 16
%d4=bitcast i8*%d3 to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit10makePhiMapE_97 to void(...)*),void(...)**%d4,align 8
%d5=getelementptr inbounds i8,i8*%dW,i64 24
%d6=bitcast i8*%d5 to i32*
store i32 -2147483647,i32*%d6,align 4
%d7=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%d8=call fastcc i8*%dM(i8*inreg%d7,i8*inreg%dW)
%d9=getelementptr inbounds i8,i8*%d8,i64 16
%ea=bitcast i8*%d9 to i8*(i8*,i8*)**
%eb=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ea,align 8
%ec=bitcast i8*%d8 to i8**
%ed=load i8*,i8**%ec,align 8
%ee=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%ef=call fastcc i8*%eb(i8*inreg%ed,i8*inreg%ee)
store i8*%ef,i8**%g,align 8
%eg=call i8*@sml_alloc(i32 inreg 20)#0
%eh=getelementptr inbounds i8,i8*%eg,i64 -4
%ei=bitcast i8*%eh to i32*
store i32 1342177296,i32*%ei,align 4
%ej=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ek=bitcast i8*%eg to i8**
store i8*%ej,i8**%ek,align 8
%el=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%em=getelementptr inbounds i8,i8*%eg,i64 8
%en=bitcast i8*%em to i8**
store i8*%el,i8**%en,align 8
%eo=getelementptr inbounds i8,i8*%eg,i64 16
%ep=bitcast i8*%eo to i32*
store i32 3,i32*%ep,align 4
%eq=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%er=call fastcc i8*%dG(i8*inreg%eq,i8*inreg%eg)
store i8*%er,i8**%f,align 8
%es=bitcast i8**%e to i8***
%et=load i8**,i8***%es,align 8
%eu=load i8*,i8**%et,align 8
store i8*%eu,i8**%g,align 8
%ev=getelementptr inbounds i8*,i8**%et,i64 1
%ew=load i8*,i8**%ev,align 8
store i8*%ew,i8**%e,align 8
%ex=call fastcc i8*@_SMLFN13FunLocalLabel3Map9singletonE(i32 inreg 1,i32 inreg 8)
%ey=getelementptr inbounds i8,i8*%ex,i64 16
%ez=bitcast i8*%ey to i8*(i8*,i8*)**
%eA=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ez,align 8
%eB=bitcast i8*%ex to i8**
%eC=load i8*,i8**%eB,align 8
store i8*%eC,i8**%i,align 8
%eD=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%eE=getelementptr inbounds i8,i8*%eD,i64 16
%eF=bitcast i8*%eE to i8*(i8*,i8*)**
%eG=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%eF,align 8
%eH=bitcast i8*%eD to i8**
%eI=load i8*,i8**%eH,align 8
store i8*%eI,i8**%h,align 8
%eJ=call i8*@sml_alloc(i32 inreg 12)#0
%eK=getelementptr inbounds i8,i8*%eJ,i64 -4
%eL=bitcast i8*%eK to i32*
store i32 1342177288,i32*%eL,align 4
store i8*%eJ,i8**%j,align 8
%eM=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%eN=bitcast i8*%eJ to i8**
store i8*%eM,i8**%eN,align 8
%eO=getelementptr inbounds i8,i8*%eJ,i64 8
%eP=bitcast i8*%eO to i32*
store i32 1,i32*%eP,align 4
%eQ=call i8*@sml_alloc(i32 inreg 28)#0
%eR=getelementptr inbounds i8,i8*%eQ,i64 -4
%eS=bitcast i8*%eR to i32*
store i32 1342177304,i32*%eS,align 4
%eT=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%eU=bitcast i8*%eQ to i8**
store i8*%eT,i8**%eU,align 8
%eV=getelementptr inbounds i8,i8*%eQ,i64 8
%eW=bitcast i8*%eV to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit10makePhiMapE_98 to void(...)*),void(...)**%eW,align 8
%eX=getelementptr inbounds i8,i8*%eQ,i64 16
%eY=bitcast i8*%eX to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit10makePhiMapE_98 to void(...)*),void(...)**%eY,align 8
%eZ=getelementptr inbounds i8,i8*%eQ,i64 24
%e0=bitcast i8*%eZ to i32*
store i32 -2147483647,i32*%e0,align 4
%e1=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%e2=call fastcc i8*%eG(i8*inreg%e1,i8*inreg%eQ)
%e3=getelementptr inbounds i8,i8*%e2,i64 16
%e4=bitcast i8*%e3 to i8*(i8*,i8*)**
%e5=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%e4,align 8
%e6=bitcast i8*%e2 to i8**
%e7=load i8*,i8**%e6,align 8
%e8=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%e9=call fastcc i8*%e5(i8*inreg%e7,i8*inreg%e8)
store i8*%e9,i8**%d,align 8
%fa=call i8*@sml_alloc(i32 inreg 20)#0
%fb=getelementptr inbounds i8,i8*%fa,i64 -4
%fc=bitcast i8*%fb to i32*
store i32 1342177296,i32*%fc,align 4
%fd=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%fe=bitcast i8*%fa to i8**
store i8*%fd,i8**%fe,align 8
%ff=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%fg=getelementptr inbounds i8,i8*%fa,i64 8
%fh=bitcast i8*%fg to i8**
store i8*%ff,i8**%fh,align 8
%fi=getelementptr inbounds i8,i8*%fa,i64 16
%fj=bitcast i8*%fi to i32*
store i32 3,i32*%fj,align 4
%fk=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%fl=call fastcc i8*%eA(i8*inreg%fk,i8*inreg%fa)
store i8*%fl,i8**%d,align 8
%fm=call fastcc i8*@_SMLFN13FunLocalLabel3Map9unionWithE(i32 inreg 1,i32 inreg 8)
%fn=getelementptr inbounds i8,i8*%fm,i64 16
%fo=bitcast i8*%fn to i8*(i8*,i8*)**
%fp=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%fo,align 8
%fq=bitcast i8*%fm to i8**
%fr=load i8*,i8**%fq,align 8
store i8*%fr,i8**%g,align 8
%fs=call fastcc i8*@_SMLFN8ListPair5mapEqE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%ft=getelementptr inbounds i8,i8*%fs,i64 16
%fu=bitcast i8*%ft to i8*(i8*,i8*)**
%fv=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%fu,align 8
%fw=bitcast i8*%fs to i8**
%fx=load i8*,i8**%fw,align 8
store i8*%fx,i8**%e,align 8
%fy=call fastcc i8*@_SMLFN4List1_VE(i32 inreg 1,i32 inreg 8)
%fz=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%fA=call fastcc i8*%fv(i8*inreg%fz,i8*inreg%fy)
%fB=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%fC=call fastcc i8*%fp(i8*inreg%fB,i8*inreg%fA)
%fD=getelementptr inbounds i8,i8*%fC,i64 16
%fE=bitcast i8*%fD to i8*(i8*,i8*)**
%fF=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%fE,align 8
%fG=bitcast i8*%fC to i8**
%fH=load i8*,i8**%fG,align 8
store i8*%fH,i8**%e,align 8
%fI=call i8*@sml_alloc(i32 inreg 20)#0
%fJ=getelementptr inbounds i8,i8*%fI,i64 -4
%fK=bitcast i8*%fJ to i32*
store i32 1342177296,i32*%fK,align 4
%fL=load i8*,i8**%f,align 8
%fM=bitcast i8*%fI to i8**
store i8*%fL,i8**%fM,align 8
%fN=load i8*,i8**%d,align 8
%fO=getelementptr inbounds i8,i8*%fI,i64 8
%fP=bitcast i8*%fO to i8**
store i8*%fN,i8**%fP,align 8
%fQ=getelementptr inbounds i8,i8*%fI,i64 16
%fR=bitcast i8*%fQ to i32*
store i32 3,i32*%fR,align 4
%fS=load i8*,i8**%e,align 8
%fT=tail call fastcc i8*%fF(i8*inreg%fS,i8*inreg%fI)
ret i8*%fT
fU:
store i8*null,i8**%g,align 8
%fV=getelementptr inbounds i8,i8*%u,i64 8
%fW=bitcast i8*%fV to i8**
%fX=load i8*,i8**%fW,align 8
%fY=bitcast i8*%fX to i8**
%fZ=load i8*,i8**%fY,align 8
store i8*%fZ,i8**%e,align 8
%f0=getelementptr inbounds i8,i8*%fX,i64 8
%f1=bitcast i8*%f0 to i8**
%f2=load i8*,i8**%f1,align 8
store i8*%f2,i8**%f,align 8
%f3=call fastcc i8*@_SMLFN13FunLocalLabel3Map9singletonE(i32 inreg 1,i32 inreg 8)
%f4=getelementptr inbounds i8,i8*%f3,i64 16
%f5=bitcast i8*%f4 to i8*(i8*,i8*)**
%f6=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%f5,align 8
%f7=bitcast i8*%f3 to i8**
%f8=load i8*,i8**%f7,align 8
store i8*%f8,i8**%h,align 8
%f9=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%ga=getelementptr inbounds i8,i8*%f9,i64 16
%gb=bitcast i8*%ga to i8*(i8*,i8*)**
%gc=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%gb,align 8
%gd=bitcast i8*%f9 to i8**
%ge=load i8*,i8**%gd,align 8
store i8*%ge,i8**%g,align 8
%gf=call i8*@sml_alloc(i32 inreg 12)#0
%gg=getelementptr inbounds i8,i8*%gf,i64 -4
%gh=bitcast i8*%gg to i32*
store i32 1342177288,i32*%gh,align 4
store i8*%gf,i8**%i,align 8
%gi=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%gj=bitcast i8*%gf to i8**
store i8*%gi,i8**%gj,align 8
%gk=getelementptr inbounds i8,i8*%gf,i64 8
%gl=bitcast i8*%gk to i32*
store i32 1,i32*%gl,align 4
%gm=call i8*@sml_alloc(i32 inreg 28)#0
%gn=getelementptr inbounds i8,i8*%gm,i64 -4
%go=bitcast i8*%gn to i32*
store i32 1342177304,i32*%go,align 4
%gp=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%gq=bitcast i8*%gm to i8**
store i8*%gp,i8**%gq,align 8
%gr=getelementptr inbounds i8,i8*%gm,i64 8
%gs=bitcast i8*%gr to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit10makePhiMapE_96 to void(...)*),void(...)**%gs,align 8
%gt=getelementptr inbounds i8,i8*%gm,i64 16
%gu=bitcast i8*%gt to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN8LLVMEmit10makePhiMapE_96 to void(...)*),void(...)**%gu,align 8
%gv=getelementptr inbounds i8,i8*%gm,i64 24
%gw=bitcast i8*%gv to i32*
store i32 -2147483647,i32*%gw,align 4
%gx=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%gy=call fastcc i8*%gc(i8*inreg%gx,i8*inreg%gm)
%gz=getelementptr inbounds i8,i8*%gy,i64 16
%gA=bitcast i8*%gz to i8*(i8*,i8*)**
%gB=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%gA,align 8
%gC=bitcast i8*%gy to i8**
%gD=load i8*,i8**%gC,align 8
%gE=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%gF=call fastcc i8*%gB(i8*inreg%gD,i8*inreg%gE)
store i8*%gF,i8**%d,align 8
%gG=call i8*@sml_alloc(i32 inreg 20)#0
%gH=getelementptr inbounds i8,i8*%gG,i64 -4
%gI=bitcast i8*%gH to i32*
store i32 1342177296,i32*%gI,align 4
%gJ=load i8*,i8**%e,align 8
%gK=bitcast i8*%gG to i8**
store i8*%gJ,i8**%gK,align 8
%gL=load i8*,i8**%d,align 8
%gM=getelementptr inbounds i8,i8*%gG,i64 8
%gN=bitcast i8*%gM to i8**
store i8*%gL,i8**%gN,align 8
%gO=getelementptr inbounds i8,i8*%gG,i64 16
%gP=bitcast i8*%gO to i32*
store i32 3,i32*%gP,align 4
%gQ=load i8*,i8**%h,align 8
%gR=tail call fastcc i8*%f6(i8*inreg%gQ,i8*inreg%gG)
ret i8*%gR
gS:
%gT=bitcast i8**%g to i8***
%gU=load i8**,i8***%gT,align 8
%gV=load i8*,i8**%gU,align 8
ret i8*%gV
gW:
%gX=bitcast i8**%g to i8***
%gY=load i8**,i8***%gX,align 8
%gZ=load i8*,i8**%gY,align 8
ret i8*%gZ
g0:
%g1=getelementptr inbounds i8,i8*%u,i64 8
%g2=bitcast i8*%g1 to i8**
%g3=load i8*,i8**%g2,align 8
%g4=getelementptr inbounds i8,i8*%g3,i64 8
%g5=bitcast i8*%g4 to i8**
%g6=load i8*,i8**%g5,align 8
store i8*%g6,i8**%e,align 8
%g7=getelementptr inbounds i8,i8*%g3,i64 32
%g8=bitcast i8*%g7 to i8**
%g9=load i8*,i8**%g8,align 8
store i8*%g9,i8**%f,align 8
%ha=getelementptr inbounds i8,i8*%g3,i64 40
%hb=bitcast i8*%ha to i8**
%hc=load i8*,i8**%hb,align 8
%hd=load i8*,i8**%d,align 8
%he=load i8*,i8**%g,align 8
store i8*null,i8**%d,align 8
%hf=call fastcc i8*@_SMLLLN8LLVMEmit10makePhiMapE_95(i8*inreg%he,i8*inreg%hd,i8*inreg%hc)
store i8*%hf,i8**%d,align 8
%hg=call i8*@sml_alloc(i32 inreg 20)#0
%hh=bitcast i8*%hg to i32*
%hi=getelementptr inbounds i8,i8*%hg,i64 -4
%hj=bitcast i8*%hi to i32*
store i32 1342177296,i32*%hj,align 4
%hk=getelementptr inbounds i8,i8*%hg,i64 4
%hl=bitcast i8*%hk to i32*
store i32 0,i32*%hl,align 1
store i32 2,i32*%hh,align 4
%hm=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%hn=getelementptr inbounds i8,i8*%hg,i64 8
%ho=bitcast i8*%hn to i8**
store i8*%hm,i8**%ho,align 8
%hp=getelementptr inbounds i8,i8*%hg,i64 16
%hq=bitcast i8*%hp to i32*
store i32 2,i32*%hq,align 4
%hr=load i8*,i8**%e,align 8
%hs=load i8*,i8**%g,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%g,align 8
%ht=call fastcc i8*@_SMLLLN8LLVMEmit10makePhiMapE_95(i8*inreg%hs,i8*inreg%hg,i8*inreg%hr)
store i8*%ht,i8**%e,align 8
%hu=call fastcc i8*@_SMLFN13FunLocalLabel3Map9unionWithE(i32 inreg 1,i32 inreg 8)
%hv=getelementptr inbounds i8,i8*%hu,i64 16
%hw=bitcast i8*%hv to i8*(i8*,i8*)**
%hx=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%hw,align 8
%hy=bitcast i8*%hu to i8**
%hz=load i8*,i8**%hy,align 8
store i8*%hz,i8**%g,align 8
%hA=call fastcc i8*@_SMLFN8ListPair5mapEqE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%hB=getelementptr inbounds i8,i8*%hA,i64 16
%hC=bitcast i8*%hB to i8*(i8*,i8*)**
%hD=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%hC,align 8
%hE=bitcast i8*%hA to i8**
%hF=load i8*,i8**%hE,align 8
store i8*%hF,i8**%f,align 8
%hG=call fastcc i8*@_SMLFN4List1_VE(i32 inreg 1,i32 inreg 8)
%hH=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%hI=call fastcc i8*%hD(i8*inreg%hH,i8*inreg%hG)
%hJ=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%hK=call fastcc i8*%hx(i8*inreg%hJ,i8*inreg%hI)
%hL=getelementptr inbounds i8,i8*%hK,i64 16
%hM=bitcast i8*%hL to i8*(i8*,i8*)**
%hN=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%hM,align 8
%hO=bitcast i8*%hK to i8**
%hP=load i8*,i8**%hO,align 8
store i8*%hP,i8**%f,align 8
%hQ=call i8*@sml_alloc(i32 inreg 20)#0
%hR=getelementptr inbounds i8,i8*%hQ,i64 -4
%hS=bitcast i8*%hR to i32*
store i32 1342177296,i32*%hS,align 4
%hT=load i8*,i8**%d,align 8
%hU=bitcast i8*%hQ to i8**
store i8*%hT,i8**%hU,align 8
%hV=load i8*,i8**%e,align 8
%hW=getelementptr inbounds i8,i8*%hQ,i64 8
%hX=bitcast i8*%hW to i8**
store i8*%hV,i8**%hX,align 8
%hY=getelementptr inbounds i8,i8*%hQ,i64 16
%hZ=bitcast i8*%hY to i32*
store i32 3,i32*%hZ,align 4
%h0=load i8*,i8**%f,align 8
%h1=tail call fastcc i8*%hN(i8*inreg%h0,i8*inreg%hQ)
ret i8*%h1
h2:
%h3=getelementptr inbounds i8,i8*%u,i64 8
%h4=bitcast i8*%h3 to i8**
%h5=load i8*,i8**%h4,align 8
%h6=bitcast i8*%h5 to i8**
%h7=load i8*,i8**%h6,align 8
store i8*%h7,i8**%e,align 8
%h8=getelementptr inbounds i8,i8*%h5,i64 8
%h9=bitcast i8*%h8 to i8**
%ia=load i8*,i8**%h9,align 8
store i8*%ia,i8**%f,align 8
%ib=getelementptr inbounds i8,i8*%h5,i64 16
%ic=bitcast i8*%ib to i8**
%id=load i8*,i8**%ic,align 8
%ie=load i8*,i8**%d,align 8
%if=load i8*,i8**%g,align 8
store i8*null,i8**%d,align 8
%ig=call fastcc i8*@_SMLLLN8LLVMEmit10makePhiMapE_95(i8*inreg%if,i8*inreg%ie,i8*inreg%id)
store i8*%ig,i8**%d,align 8
%ih=call i8*@sml_alloc(i32 inreg 20)#0
%ii=bitcast i8*%ih to i32*
%ij=getelementptr inbounds i8,i8*%ih,i64 -4
%ik=bitcast i8*%ij to i32*
store i32 1342177296,i32*%ik,align 4
%il=getelementptr inbounds i8,i8*%ih,i64 4
%im=bitcast i8*%il to i32*
store i32 0,i32*%im,align 1
store i32 1,i32*%ii,align 4
%in=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%io=getelementptr inbounds i8,i8*%ih,i64 8
%ip=bitcast i8*%io to i8**
store i8*%in,i8**%ip,align 8
%iq=getelementptr inbounds i8,i8*%ih,i64 16
%ir=bitcast i8*%iq to i32*
store i32 2,i32*%ir,align 4
%is=load i8*,i8**%e,align 8
%it=load i8*,i8**%g,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%g,align 8
%iu=call fastcc i8*@_SMLLLN8LLVMEmit10makePhiMapE_95(i8*inreg%it,i8*inreg%ih,i8*inreg%is)
store i8*%iu,i8**%e,align 8
%iv=call fastcc i8*@_SMLFN13FunLocalLabel3Map9unionWithE(i32 inreg 1,i32 inreg 8)
%iw=getelementptr inbounds i8,i8*%iv,i64 16
%ix=bitcast i8*%iw to i8*(i8*,i8*)**
%iy=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ix,align 8
%iz=bitcast i8*%iv to i8**
%iA=load i8*,i8**%iz,align 8
store i8*%iA,i8**%g,align 8
%iB=call fastcc i8*@_SMLFN8ListPair5mapEqE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%iC=getelementptr inbounds i8,i8*%iB,i64 16
%iD=bitcast i8*%iC to i8*(i8*,i8*)**
%iE=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%iD,align 8
%iF=bitcast i8*%iB to i8**
%iG=load i8*,i8**%iF,align 8
store i8*%iG,i8**%f,align 8
%iH=call fastcc i8*@_SMLFN4List1_VE(i32 inreg 1,i32 inreg 8)
%iI=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%iJ=call fastcc i8*%iE(i8*inreg%iI,i8*inreg%iH)
%iK=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%iL=call fastcc i8*%iy(i8*inreg%iK,i8*inreg%iJ)
%iM=getelementptr inbounds i8,i8*%iL,i64 16
%iN=bitcast i8*%iM to i8*(i8*,i8*)**
%iO=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%iN,align 8
%iP=bitcast i8*%iL to i8**
%iQ=load i8*,i8**%iP,align 8
store i8*%iQ,i8**%f,align 8
%iR=call i8*@sml_alloc(i32 inreg 20)#0
%iS=getelementptr inbounds i8,i8*%iR,i64 -4
%iT=bitcast i8*%iS to i32*
store i32 1342177296,i32*%iT,align 4
%iU=load i8*,i8**%d,align 8
%iV=bitcast i8*%iR to i8**
store i8*%iU,i8**%iV,align 8
%iW=load i8*,i8**%e,align 8
%iX=getelementptr inbounds i8,i8*%iR,i64 8
%iY=bitcast i8*%iX to i8**
store i8*%iW,i8**%iY,align 8
%iZ=getelementptr inbounds i8,i8*%iR,i64 16
%i0=bitcast i8*%iZ to i32*
store i32 3,i32*%i0,align 4
%i1=load i8*,i8**%f,align 8
%i2=tail call fastcc i8*%iO(i8*inreg%i1,i8*inreg%iR)
ret i8*%i2
}
define internal fastcc i8*@_SMLLL7phiArgs_113(i8*inreg%a)#4 gc"smlsharp"{
ret i8*null
}
define internal fastcc i8*@_SMLLL4phis_115(i8*inreg%a)#4 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
%e=bitcast i8*%a to i8**
%f=load i8*,i8**%e,align 8
%g=bitcast i8*%f to i32*
%h=load i32,i32*%g,align 4
%i=icmp eq i32%h,0
br i1%i,label%k,label%j
j:
ret i8*%f
k:
%l=getelementptr inbounds i8,i8*%f,i64 8
%m=bitcast i8*%l to i8**
%n=load i8*,i8**%m,align 8
%o=bitcast i8*%n to i8**
%p=load i8*,i8**%o,align 8
store i8*%p,i8**%b,align 8
%q=getelementptr inbounds i8,i8*%n,i64 8
%r=bitcast i8*%q to i32*
%s=load i32,i32*%r,align 4
%t=getelementptr inbounds i8,i8*%a,i64 8
%u=bitcast i8*%t to i8**
%v=load i8*,i8**%u,align 8
store i8*%v,i8**%c,align 8
%w=call i8*@sml_alloc(i32 inreg 28)#0
%x=getelementptr inbounds i8,i8*%w,i64 -4
%y=bitcast i8*%x to i32*
store i32 1342177304,i32*%y,align 4
store i8*%w,i8**%d,align 8
%z=getelementptr inbounds i8,i8*%w,i64 4
%A=bitcast i8*%z to i32*
store i32 0,i32*%A,align 1
%B=bitcast i8*%w to i32*
store i32%s,i32*%B,align 4
%C=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%D=getelementptr inbounds i8,i8*%w,i64 8
%E=bitcast i8*%D to i8**
store i8*%C,i8**%E,align 8
%F=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%G=getelementptr inbounds i8,i8*%w,i64 16
%H=bitcast i8*%G to i8**
store i8*%F,i8**%H,align 8
%I=getelementptr inbounds i8,i8*%w,i64 24
%J=bitcast i8*%I to i32*
store i32 6,i32*%J,align 4
%K=call i8*@sml_alloc(i32 inreg 20)#0
%L=bitcast i8*%K to i32*
%M=getelementptr inbounds i8,i8*%K,i64 -4
%N=bitcast i8*%M to i32*
store i32 1342177296,i32*%N,align 4
%O=getelementptr inbounds i8,i8*%K,i64 4
%P=bitcast i8*%O to i32*
store i32 0,i32*%P,align 1
store i32 1,i32*%L,align 4
%Q=load i8*,i8**%d,align 8
%R=getelementptr inbounds i8,i8*%K,i64 8
%S=bitcast i8*%R to i8**
store i8*%Q,i8**%S,align 8
%T=getelementptr inbounds i8,i8*%K,i64 16
%U=bitcast i8*%T to i32*
store i32 2,i32*%U,align 4
ret i8*%K
}
define internal fastcc i8*@_SMLLLN8LLVMEmit15completePhiBodyE_104(i8*inreg%a,i8*inreg%b)unnamed_addr#2 gc"smlsharp"personality i32(...)*@sml_personality{
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
store i8*%s,i8**%c,align 8
%t=getelementptr inbounds i8,i8*%p,i64 8
%u=bitcast i8*%t to i8**
%v=load i8*,i8**%u,align 8
%w=bitcast i8*%v to i32*
%x=load i32,i32*%w,align 4
switch i32%x,label%y[
i32 0,label%a6
i32 4,label%Y
i32 6,label%X
i32 7,label%W
i32 1,label%V
i32 2,label%U
i32 3,label%T
i32 5,label%S
i32 8,label%R
i32 9,label%Q
]
y:
store i8*null,i8**%i,align 8
call void@sml_matchcomp_bug()
%z=load i8*,i8**@_SMLZ5Match,align 8
store i8*%z,i8**%c,align 8
%A=call i8*@sml_alloc(i32 inreg 20)#0
%B=getelementptr inbounds i8,i8*%A,i64 -4
%C=bitcast i8*%B to i32*
store i32 1342177296,i32*%C,align 4
store i8*%A,i8**%d,align 8
%D=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%E=bitcast i8*%A to i8**
store i8*%D,i8**%E,align 8
%F=getelementptr inbounds i8,i8*%A,i64 8
%G=bitcast i8*%F to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[65x i8]}>,<{[4x i8],i32,[65x i8]}>*@g,i64 0,i32 2,i64 0),i8**%G,align 8
%H=getelementptr inbounds i8,i8*%A,i64 16
%I=bitcast i8*%H to i32*
store i32 3,i32*%I,align 4
%J=call i8*@sml_alloc(i32 inreg 60)#0
%K=getelementptr inbounds i8,i8*%J,i64 -4
%L=bitcast i8*%K to i32*
store i32 1342177336,i32*%L,align 4
%M=getelementptr inbounds i8,i8*%J,i64 56
%N=bitcast i8*%M to i32*
store i32 1,i32*%N,align 4
%O=load i8*,i8**%d,align 8
%P=bitcast i8*%J to i8**
store i8*%O,i8**%P,align 8
call void@sml_raise(i8*inreg%J)#1
unreachable
Q:
store i8*null,i8**%i,align 8
store i8*%v,i8**%d,align 8
br label%dv
R:
store i8*null,i8**%i,align 8
store i8*%v,i8**%d,align 8
br label%dv
S:
store i8*null,i8**%i,align 8
store i8*%v,i8**%d,align 8
br label%dv
T:
store i8*null,i8**%i,align 8
store i8*%v,i8**%d,align 8
br label%dv
U:
store i8*null,i8**%i,align 8
store i8*%v,i8**%d,align 8
br label%dv
V:
store i8*null,i8**%i,align 8
store i8*%v,i8**%d,align 8
br label%dv
W:
store i8*null,i8**%i,align 8
store i8*%v,i8**%d,align 8
br label%dv
X:
store i8*null,i8**%i,align 8
store i8*%v,i8**%d,align 8
br label%dv
Y:
%Z=getelementptr inbounds i8,i8*%v,i64 8
%aa=bitcast i8*%Z to i8**
%ab=load i8*,i8**%aa,align 8
%ac=bitcast i8*%ab to i8**
%ad=load i8*,i8**%ac,align 8
store i8*%ad,i8**%d,align 8
%ae=getelementptr inbounds i8,i8*%ab,i64 8
%af=bitcast i8*%ae to i8**
%ag=load i8*,i8**%af,align 8
%ah=getelementptr inbounds i8,i8*%ab,i64 16
%ai=bitcast i8*%ah to i8**
%aj=load i8*,i8**%ai,align 8
store i8*%aj,i8**%e,align 8
%ak=getelementptr inbounds i8,i8*%ab,i64 24
%al=bitcast i8*%ak to i32*
%am=load i32,i32*%al,align 4
%an=getelementptr inbounds i8,i8*%ab,i64 32
%ao=bitcast i8*%an to i8**
%ap=load i8*,i8**%ao,align 8
store i8*%ap,i8**%f,align 8
%aq=getelementptr inbounds i8,i8*%ab,i64 40
%ar=bitcast i8*%aq to i8**
%as=load i8*,i8**%ar,align 8
store i8*%as,i8**%g,align 8
%at=load i8*,i8**%i,align 8
%au=call fastcc i8*@_SMLLLN8LLVMEmit15completePhiBodyE_104(i8*inreg%at,i8*inreg%ag)
store i8*%au,i8**%h,align 8
%av=load i8*,i8**%g,align 8
%aw=load i8*,i8**%i,align 8
store i8*null,i8**%g,align 8
store i8*null,i8**%i,align 8
%ax=call fastcc i8*@_SMLLLN8LLVMEmit15completePhiBodyE_104(i8*inreg%aw,i8*inreg%av)
store i8*%ax,i8**%g,align 8
%ay=call i8*@sml_alloc(i32 inreg 52)#0
%az=getelementptr inbounds i8,i8*%ay,i64 -4
%aA=bitcast i8*%az to i32*
store i32 1342177328,i32*%aA,align 4
store i8*%ay,i8**%i,align 8
%aB=getelementptr inbounds i8,i8*%ay,i64 28
%aC=bitcast i8*%aB to i32*
store i32 0,i32*%aC,align 1
%aD=load i8*,i8**%d,align 8
%aE=bitcast i8*%ay to i8**
store i8*null,i8**%d,align 8
store i8*%aD,i8**%aE,align 8
%aF=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%aG=getelementptr inbounds i8,i8*%ay,i64 8
%aH=bitcast i8*%aG to i8**
store i8*%aF,i8**%aH,align 8
%aI=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aJ=getelementptr inbounds i8,i8*%ay,i64 16
%aK=bitcast i8*%aJ to i8**
store i8*%aI,i8**%aK,align 8
%aL=getelementptr inbounds i8,i8*%ay,i64 24
%aM=bitcast i8*%aL to i32*
store i32%am,i32*%aM,align 4
%aN=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aO=getelementptr inbounds i8,i8*%ay,i64 32
%aP=bitcast i8*%aO to i8**
store i8*%aN,i8**%aP,align 8
%aQ=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aR=getelementptr inbounds i8,i8*%ay,i64 40
%aS=bitcast i8*%aR to i8**
store i8*%aQ,i8**%aS,align 8
%aT=getelementptr inbounds i8,i8*%ay,i64 48
%aU=bitcast i8*%aT to i32*
store i32 55,i32*%aU,align 4
%aV=call i8*@sml_alloc(i32 inreg 20)#0
%aW=bitcast i8*%aV to i32*
%aX=getelementptr inbounds i8,i8*%aV,i64 -4
%aY=bitcast i8*%aX to i32*
store i32 1342177296,i32*%aY,align 4
%aZ=getelementptr inbounds i8,i8*%aV,i64 4
%a0=bitcast i8*%aZ to i32*
store i32 0,i32*%a0,align 1
store i32 4,i32*%aW,align 4
%a1=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%a2=getelementptr inbounds i8,i8*%aV,i64 8
%a3=bitcast i8*%a2 to i8**
store i8*%a1,i8**%a3,align 8
%a4=getelementptr inbounds i8,i8*%aV,i64 16
%a5=bitcast i8*%a4 to i32*
store i32 2,i32*%a5,align 4
store i8*%aV,i8**%d,align 8
br label%dv
a6:
%a7=getelementptr inbounds i8,i8*%v,i64 8
%a8=bitcast i8*%a7 to i8**
%a9=load i8*,i8**%a8,align 8
%ba=bitcast i8*%a9 to i8**
%bb=load i8*,i8**%ba,align 8
store i8*%bb,i8**%d,align 8
%bc=getelementptr inbounds i8,i8*%a9,i64 8
%bd=bitcast i8*%bc to i8**
%be=load i8*,i8**%bd,align 8
store i8*%be,i8**%e,align 8
%bf=getelementptr inbounds i8,i8*%a9,i64 16
%bg=bitcast i8*%bf to i8**
%bh=load i8*,i8**%bg,align 8
store i8*%bh,i8**%f,align 8
%bi=getelementptr inbounds i8,i8*%a9,i64 24
%bj=bitcast i8*%bi to i8**
%bk=load i8*,i8**%bj,align 8
store i8*%bk,i8**%g,align 8
%bl=call fastcc i8*@_SMLFN13FunLocalLabel3Map4findE(i32 inreg 1,i32 inreg 8)
%bm=getelementptr inbounds i8,i8*%bl,i64 16
%bn=bitcast i8*%bm to i8*(i8*,i8*)**
%bo=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bn,align 8
%bp=bitcast i8*%bl to i8**
%bq=load i8*,i8**%bp,align 8
store i8*%bq,i8**%h,align 8
%br=call i8*@sml_alloc(i32 inreg 20)#0
%bs=getelementptr inbounds i8,i8*%br,i64 -4
%bt=bitcast i8*%bs to i32*
store i32 1342177296,i32*%bt,align 4
%bu=load i8*,i8**%i,align 8
%bv=bitcast i8*%br to i8**
store i8*%bu,i8**%bv,align 8
%bw=load i8*,i8**%e,align 8
%bx=getelementptr inbounds i8,i8*%br,i64 8
%by=bitcast i8*%bx to i8**
store i8*%bw,i8**%by,align 8
%bz=getelementptr inbounds i8,i8*%br,i64 16
%bA=bitcast i8*%bz to i32*
store i32 3,i32*%bA,align 4
%bB=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%bC=call fastcc i8*%bo(i8*inreg%bB,i8*inreg%br)
%bD=icmp eq i8*%bC,null
br i1%bD,label%bE,label%bT
bE:
%bF=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%bG=getelementptr inbounds i8,i8*%bF,i64 16
%bH=bitcast i8*%bG to i8*(i8*,i8*)**
%bI=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bH,align 8
%bJ=bitcast i8*%bF to i8**
%bK=load i8*,i8**%bJ,align 8
%bL=call fastcc i8*%bI(i8*inreg%bK,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*))
%bM=getelementptr inbounds i8,i8*%bL,i64 16
%bN=bitcast i8*%bM to i8*(i8*,i8*)**
%bO=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bN,align 8
%bP=bitcast i8*%bL to i8**
%bQ=load i8*,i8**%bP,align 8
%bR=load i8*,i8**%g,align 8
%bS=call fastcc i8*%bO(i8*inreg%bQ,i8*inreg%bR)
br label%bW
bT:
%bU=bitcast i8*%bC to i8**
%bV=load i8*,i8**%bU,align 8
br label%bW
bW:
%bX=phi i8*[%bV,%bT],[%bS,%bE]
store i8*%bX,i8**%h,align 8
%bY=invoke fastcc i8*@_SMLFN8ListPair5mapEqE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
to label%bZ unwind label%cU
bZ:
%b0=getelementptr inbounds i8,i8*%bY,i64 16
%b1=bitcast i8*%b0 to i8*(i8*,i8*)**
%b2=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%b1,align 8
%b3=bitcast i8*%bY to i8**
%b4=load i8*,i8**%b3,align 8
%b5=invoke fastcc i8*%b2(i8*inreg%b4,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@d,i64 0,i32 2)to i8*))
to label%b6 unwind label%cU
b6:
%b7=getelementptr inbounds i8,i8*%b5,i64 16
%b8=bitcast i8*%b7 to i8*(i8*,i8*)**
%b9=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%b8,align 8
%ca=bitcast i8*%b5 to i8**
%cb=load i8*,i8**%ca,align 8
store i8*%cb,i8**%j,align 8
%cc=call i8*@sml_alloc(i32 inreg 20)#0
%cd=getelementptr inbounds i8,i8*%cc,i64 -4
%ce=bitcast i8*%cd to i32*
store i32 1342177296,i32*%ce,align 4
%cf=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%cg=bitcast i8*%cc to i8**
store i8*%cf,i8**%cg,align 8
%ch=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%ci=getelementptr inbounds i8,i8*%cc,i64 8
%cj=bitcast i8*%ci to i8**
store i8*%ch,i8**%cj,align 8
%ck=getelementptr inbounds i8,i8*%cc,i64 16
%cl=bitcast i8*%ck to i32*
store i32 3,i32*%cl,align 4
%cm=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%cn=invoke fastcc i8*%b9(i8*inreg%cm,i8*inreg%cc)
to label%co unwind label%cU
co:
store i8*%cn,i8**%h,align 8
%cp=load i8*,i8**%d,align 8
%cq=load i8*,i8**%i,align 8
store i8*null,i8**%d,align 8
%cr=call fastcc i8*@_SMLLLN8LLVMEmit15completePhiBodyE_104(i8*inreg%cq,i8*inreg%cp)
store i8*%cr,i8**%d,align 8
%cs=load i8*,i8**%f,align 8
%ct=load i8*,i8**%i,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%i,align 8
%cu=call fastcc i8*@_SMLLLN8LLVMEmit15completePhiBodyE_104(i8*inreg%ct,i8*inreg%cs)
store i8*%cu,i8**%f,align 8
%cv=call i8*@sml_alloc(i32 inreg 36)#0
%cw=getelementptr inbounds i8,i8*%cv,i64 -4
%cx=bitcast i8*%cw to i32*
store i32 1342177312,i32*%cx,align 4
store i8*%cv,i8**%g,align 8
%cy=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%cz=bitcast i8*%cv to i8**
store i8*%cy,i8**%cz,align 8
%cA=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%cB=getelementptr inbounds i8,i8*%cv,i64 8
%cC=bitcast i8*%cB to i8**
store i8*%cA,i8**%cC,align 8
%cD=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%cE=getelementptr inbounds i8,i8*%cv,i64 16
%cF=bitcast i8*%cE to i8**
store i8*%cD,i8**%cF,align 8
%cG=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%cH=getelementptr inbounds i8,i8*%cv,i64 24
%cI=bitcast i8*%cH to i8**
store i8*%cG,i8**%cI,align 8
%cJ=getelementptr inbounds i8,i8*%cv,i64 32
%cK=bitcast i8*%cJ to i32*
store i32 15,i32*%cK,align 4
%cL=call i8*@sml_alloc(i32 inreg 20)#0
%cM=getelementptr inbounds i8,i8*%cL,i64 -4
%cN=bitcast i8*%cM to i32*
store i32 1342177296,i32*%cN,align 4
%cO=bitcast i8*%cL to i64*
store i64 0,i64*%cO,align 4
%cP=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%cQ=getelementptr inbounds i8,i8*%cL,i64 8
%cR=bitcast i8*%cQ to i8**
store i8*%cP,i8**%cR,align 8
%cS=getelementptr inbounds i8,i8*%cL,i64 16
%cT=bitcast i8*%cS to i32*
store i32 2,i32*%cT,align 4
store i8*%cL,i8**%d,align 8
br label%dv
cU:
%cV=landingpad{i8*,i8*}
catch i8*null
%cW=extractvalue{i8*,i8*}%cV,1
%cX=bitcast i8*%cW to i8**
%cY=load i8*,i8**%cX,align 8
store i8*null,i8**%d,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%g,align 8
store i8*null,i8**%h,align 8
store i8*null,i8**%i,align 8
store i8*%cY,i8**%c,align 8
%cZ=bitcast i8*%cY to i8**
%c0=load i8*,i8**%cZ,align 8
%c1=load i8*,i8**@_SMLZN8ListPair14UnequalLengthsE,align 8
%c2=icmp eq i8*%c0,%c1
br i1%c2,label%c3,label%dn
c3:
%c4=load i8*,i8**@_SMLZN3Bug3BugE,align 8
store i8*%c4,i8**%c,align 8
%c5=call i8*@sml_alloc(i32 inreg 28)#0
%c6=getelementptr inbounds i8,i8*%c5,i64 -4
%c7=bitcast i8*%c6 to i32*
store i32 1342177304,i32*%c7,align 4
store i8*%c5,i8**%d,align 8
%c8=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%c9=bitcast i8*%c5 to i8**
store i8*%c8,i8**%c9,align 8
%da=getelementptr inbounds i8,i8*%c5,i64 8
%db=bitcast i8*%da to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[66x i8]}>,<{[4x i8],i32,[66x i8]}>*@e,i64 0,i32 2,i64 0),i8**%db,align 8
%dc=getelementptr inbounds i8,i8*%c5,i64 16
%dd=bitcast i8*%dc to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[16x i8]}>,<{[4x i8],i32,[16x i8]}>*@f,i64 0,i32 2,i64 0),i8**%dd,align 8
%de=getelementptr inbounds i8,i8*%c5,i64 24
%df=bitcast i8*%de to i32*
store i32 7,i32*%df,align 4
%dg=call i8*@sml_alloc(i32 inreg 60)#0
%dh=getelementptr inbounds i8,i8*%dg,i64 -4
%di=bitcast i8*%dh to i32*
store i32 1342177336,i32*%di,align 4
%dj=getelementptr inbounds i8,i8*%dg,i64 56
%dk=bitcast i8*%dj to i32*
store i32 1,i32*%dk,align 4
%dl=load i8*,i8**%d,align 8
%dm=bitcast i8*%dg to i8**
store i8*%dl,i8**%dm,align 8
call void@sml_raise(i8*inreg%dg)#1
unreachable
dn:
%do=call i8*@sml_alloc(i32 inreg 60)#0
%dp=getelementptr inbounds i8,i8*%do,i64 -4
%dq=bitcast i8*%dp to i32*
store i32 1342177336,i32*%dq,align 4
%dr=getelementptr inbounds i8,i8*%do,i64 56
%ds=bitcast i8*%dr to i32*
store i32 1,i32*%ds,align 4
%dt=load i8*,i8**%c,align 8
%du=bitcast i8*%do to i8**
store i8*%dt,i8**%du,align 8
call void@sml_raise(i8*inreg%do)#1
unreachable
dv:
%dw=call i8*@sml_alloc(i32 inreg 20)#0
%dx=getelementptr inbounds i8,i8*%dw,i64 -4
%dy=bitcast i8*%dx to i32*
store i32 1342177296,i32*%dy,align 4
%dz=load i8*,i8**%c,align 8
%dA=bitcast i8*%dw to i8**
store i8*%dz,i8**%dA,align 8
%dB=load i8*,i8**%d,align 8
%dC=getelementptr inbounds i8,i8*%dw,i64 8
%dD=bitcast i8*%dC to i8**
store i8*%dB,i8**%dD,align 8
%dE=getelementptr inbounds i8,i8*%dw,i64 16
%dF=bitcast i8*%dE to i32*
store i32 3,i32*%dF,align 4
ret i8*%dw
}
define internal fastcc i8*@_SMLLLN8LLVMEmit17completePhiTopdecE_121(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
t:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
%k=alloca i8*,align 8
%l=alloca i8*,align 8
%m=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
call void@llvm.gcroot(i8**%k,i8*null)#0
call void@llvm.gcroot(i8**%l,i8*null)#0
call void@llvm.gcroot(i8**%m,i8*null)#0
store i8*%a,i8**%e,align 8
store i8*%b,i8**%c,align 8
%n=load atomic i32,i32*@sml_check_flag unordered,align 4
%o=icmp eq i32%n,0
br i1%o,label%r,label%p
p:
call void@sml_check(i32 inreg%n)
%q=load i8*,i8**%c,align 8
br label%r
r:
%s=phi i8*[%q,%p],[%b,%t]
%u=bitcast i8*%s to i32*
%v=load i32,i32*%u,align 4
switch i32%v,label%w[
i32 2,label%P
i32 1,label%O
i32 4,label%O
i32 0,label%O
i32 3,label%O
]
w:
store i8*null,i8**%e,align 8
call void@sml_matchcomp_bug()
%x=load i8*,i8**@_SMLZ5Match,align 8
store i8*%x,i8**%c,align 8
%y=call i8*@sml_alloc(i32 inreg 20)#0
%z=getelementptr inbounds i8,i8*%y,i64 -4
%A=bitcast i8*%z to i32*
store i32 1342177296,i32*%A,align 4
store i8*%y,i8**%d,align 8
%B=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%C=bitcast i8*%y to i8**
store i8*%B,i8**%C,align 8
%D=getelementptr inbounds i8,i8*%y,i64 8
%E=bitcast i8*%D to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[65x i8]}>,<{[4x i8],i32,[65x i8]}>*@h,i64 0,i32 2,i64 0),i8**%E,align 8
%F=getelementptr inbounds i8,i8*%y,i64 16
%G=bitcast i8*%F to i32*
store i32 3,i32*%G,align 4
%H=call i8*@sml_alloc(i32 inreg 60)#0
%I=getelementptr inbounds i8,i8*%H,i64 -4
%J=bitcast i8*%I to i32*
store i32 1342177336,i32*%J,align 4
%K=getelementptr inbounds i8,i8*%H,i64 56
%L=bitcast i8*%K to i32*
store i32 1,i32*%L,align 4
%M=load i8*,i8**%d,align 8
%N=bitcast i8*%H to i8**
store i8*%M,i8**%N,align 8
call void@sml_raise(i8*inreg%H)#1
unreachable
O:
ret i8*%s
P:
%Q=getelementptr inbounds i8,i8*%s,i64 8
%R=bitcast i8*%Q to i8**
%S=load i8*,i8**%R,align 8
store i8*%S,i8**%c,align 8
%T=bitcast i8*%S to i8**
%U=load i8*,i8**%T,align 8
store i8*%U,i8**%d,align 8
%V=bitcast i8**%e to i8***
%W=load i8**,i8***%V,align 8
store i8*null,i8**%e,align 8
%X=load i8*,i8**%W,align 8
%Y=call fastcc i8*@_SMLLLN8LLVMEmit10makePhiMapE_95(i8*inreg%X,i8*inreg null,i8*inreg%U)
%Z=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aa=call fastcc i8*@_SMLLLN8LLVMEmit15completePhiBodyE_104(i8*inreg%Y,i8*inreg%Z)
store i8*%aa,i8**%d,align 8
%ab=load i8*,i8**%c,align 8
%ac=getelementptr inbounds i8,i8*%ab,i64 8
%ad=bitcast i8*%ac to i8**
%ae=load i8*,i8**%ad,align 8
store i8*%ae,i8**%e,align 8
%af=getelementptr inbounds i8,i8*%ab,i64 16
%ag=bitcast i8*%af to i8**
%ah=load i8*,i8**%ag,align 8
store i8*%ah,i8**%f,align 8
%ai=getelementptr inbounds i8,i8*%ab,i64 24
%aj=bitcast i8*%ai to i8**
%ak=load i8*,i8**%aj,align 8
store i8*%ak,i8**%g,align 8
%al=getelementptr inbounds i8,i8*%ab,i64 32
%am=bitcast i8*%al to i8**
%an=load i8*,i8**%am,align 8
store i8*%an,i8**%h,align 8
%ao=getelementptr inbounds i8,i8*%ab,i64 40
%ap=bitcast i8*%ao to i8**
%aq=load i8*,i8**%ap,align 8
store i8*%aq,i8**%i,align 8
%ar=getelementptr inbounds i8,i8*%ab,i64 48
%as=bitcast i8*%ar to i8**
%at=load i8*,i8**%as,align 8
store i8*%at,i8**%j,align 8
%au=getelementptr inbounds i8,i8*%ab,i64 56
%av=bitcast i8*%au to i8**
%aw=load i8*,i8**%av,align 8
store i8*%aw,i8**%k,align 8
%ax=getelementptr inbounds i8,i8*%ab,i64 64
%ay=bitcast i8*%ax to i8**
%az=load i8*,i8**%ay,align 8
store i8*%az,i8**%l,align 8
%aA=getelementptr inbounds i8,i8*%ab,i64 72
%aB=bitcast i8*%aA to i8**
%aC=load i8*,i8**%aB,align 8
store i8*%aC,i8**%c,align 8
%aD=call i8*@sml_alloc(i32 inreg 84)#0
%aE=getelementptr inbounds i8,i8*%aD,i64 -4
%aF=bitcast i8*%aE to i32*
store i32 1342177360,i32*%aF,align 4
store i8*%aD,i8**%m,align 8
%aG=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aH=bitcast i8*%aD to i8**
store i8*%aG,i8**%aH,align 8
%aI=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aJ=getelementptr inbounds i8,i8*%aD,i64 8
%aK=bitcast i8*%aJ to i8**
store i8*%aI,i8**%aK,align 8
%aL=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aM=getelementptr inbounds i8,i8*%aD,i64 16
%aN=bitcast i8*%aM to i8**
store i8*%aL,i8**%aN,align 8
%aO=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aP=getelementptr inbounds i8,i8*%aD,i64 24
%aQ=bitcast i8*%aP to i8**
store i8*%aO,i8**%aQ,align 8
%aR=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%aS=getelementptr inbounds i8,i8*%aD,i64 32
%aT=bitcast i8*%aS to i8**
store i8*%aR,i8**%aT,align 8
%aU=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%aV=getelementptr inbounds i8,i8*%aD,i64 40
%aW=bitcast i8*%aV to i8**
store i8*%aU,i8**%aW,align 8
%aX=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%aY=getelementptr inbounds i8,i8*%aD,i64 48
%aZ=bitcast i8*%aY to i8**
store i8*%aX,i8**%aZ,align 8
%a0=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
%a1=getelementptr inbounds i8,i8*%aD,i64 56
%a2=bitcast i8*%a1 to i8**
store i8*%a0,i8**%a2,align 8
%a3=load i8*,i8**%l,align 8
store i8*null,i8**%l,align 8
%a4=getelementptr inbounds i8,i8*%aD,i64 64
%a5=bitcast i8*%a4 to i8**
store i8*%a3,i8**%a5,align 8
%a6=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%a7=getelementptr inbounds i8,i8*%aD,i64 72
%a8=bitcast i8*%a7 to i8**
store i8*%a6,i8**%a8,align 8
%a9=getelementptr inbounds i8,i8*%aD,i64 80
%ba=bitcast i8*%a9 to i32*
store i32 1023,i32*%ba,align 4
%bb=call i8*@sml_alloc(i32 inreg 20)#0
%bc=bitcast i8*%bb to i32*
%bd=getelementptr inbounds i8,i8*%bb,i64 -4
%be=bitcast i8*%bd to i32*
store i32 1342177296,i32*%be,align 4
%bf=getelementptr inbounds i8,i8*%bb,i64 4
%bg=bitcast i8*%bf to i32*
store i32 0,i32*%bg,align 1
store i32 2,i32*%bc,align 4
%bh=load i8*,i8**%m,align 8
%bi=getelementptr inbounds i8,i8*%bb,i64 8
%bj=bitcast i8*%bi to i8**
store i8*%bh,i8**%bj,align 8
%bk=getelementptr inbounds i8,i8*%bb,i64 16
%bl=bitcast i8*%bk to i32*
store i32 2,i32*%bl,align 4
ret i8*%bb
}
define internal fastcc i8@_SMLLL6spaces_124(i32 inreg%a)#4 gc"smlsharp"{
ret i8 32
}
define internal fastcc i8*@_SMLLLN8LLVMEmit4emitE_129(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"personality i32(...)*@sml_personality{
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
store i8*%a,i8**%g,align 8
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
%o=bitcast i8*%m to i8**
%p=load i8*,i8**%o,align 8
store i8*%p,i8**%c,align 8
%q=getelementptr inbounds i8,i8*%m,i64 8
%r=bitcast i8*%q to i8**
%s=load i8*,i8**%r,align 8
store i8*%s,i8**%d,align 8
%t=getelementptr inbounds i8,i8*%m,i64 16
%u=bitcast i8*%t to i8**
%v=load i8*,i8**%u,align 8
store i8*%v,i8**%e,align 8
%w=getelementptr inbounds i8,i8*%m,i64 24
%x=bitcast i8*%w to i8**
%y=load i8*,i8**%x,align 8
store i8*%y,i8**%f,align 8
%z=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%A=getelementptr inbounds i8,i8*%z,i64 16
%B=bitcast i8*%A to i8*(i8*,i8*)**
%C=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%B,align 8
%D=bitcast i8*%z to i8**
%E=load i8*,i8**%D,align 8
%F=bitcast i8**%g to i8***
%G=load i8**,i8***%F,align 8
store i8*null,i8**%g,align 8
%H=load i8*,i8**%G,align 8
%I=call fastcc i8*%C(i8*inreg%E,i8*inreg%H)
%J=getelementptr inbounds i8,i8*%I,i64 16
%K=bitcast i8*%J to i8*(i8*,i8*)**
%L=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%K,align 8
%M=bitcast i8*%I to i8**
%N=load i8*,i8**%M,align 8
%O=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%P=call fastcc i8*%L(i8*inreg%N,i8*inreg%O)
store i8*%P,i8**%e,align 8
%Q=call i8*@sml_alloc(i32 inreg 36)#0
%R=getelementptr inbounds i8,i8*%Q,i64 -4
%S=bitcast i8*%R to i32*
store i32 1342177312,i32*%S,align 4
%T=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%U=bitcast i8*%Q to i8**
store i8*%T,i8**%U,align 8
%V=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%W=getelementptr inbounds i8,i8*%Q,i64 8
%X=bitcast i8*%W to i8**
store i8*%V,i8**%X,align 8
%Y=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%Z=getelementptr inbounds i8,i8*%Q,i64 16
%aa=bitcast i8*%Z to i8**
store i8*%Y,i8**%aa,align 8
%ab=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ac=getelementptr inbounds i8,i8*%Q,i64 24
%ad=bitcast i8*%ac to i8**
store i8*%ab,i8**%ad,align 8
%ae=getelementptr inbounds i8,i8*%Q,i64 32
%af=bitcast i8*%ae to i32*
store i32 15,i32*%af,align 4
%ag=call fastcc i8*@_SMLFN6LLVMIR14format__programE(i8*inreg%Q)
store i8*%ag,i8**%c,align 8
%ah=load i8*,i8**@_SMLZN9LLVMUtils6ASMEXTE,align 8
store i8*%ah,i8**%d,align 8
%ai=call i8*@sml_alloc(i32 inreg 20)#0
%aj=getelementptr inbounds i8,i8*%ai,i64 -4
%ak=bitcast i8*%aj to i32*
store i32 1342177296,i32*%ak,align 4
%al=bitcast i8*%ai to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@i,i64 0,i32 2,i64 0),i8**%al,align 8
%am=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%an=getelementptr inbounds i8,i8*%ai,i64 8
%ao=bitcast i8*%an to i8**
store i8*%am,i8**%ao,align 8
%ap=getelementptr inbounds i8,i8*%ai,i64 16
%aq=bitcast i8*%ap to i32*
store i32 3,i32*%aq,align 4
%ar=call fastcc i8*@_SMLFN6String1_ZE(i8*inreg%ai)
%as=call fastcc i8*@_SMLFN8TempFile6createE(i8*inreg%ar)
store i8*%as,i8**%d,align 8
%at=call fastcc i8*@_SMLFN8Filename8toStringE(i8*inreg%as)
store i8*%at,i8**%e,align 8
call void@sml_leave()#0
%au=call i8*@fopen(i8*%at,i8*getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@j,i64 0,i32 2,i64 0))
call void@sml_enter()#0
store i8*null,i8**%e,align 8
%av=call fastcc i8*@_SMLFN7Pointer6isNullE(i32 inreg 0,i32 inreg 4)
%aw=getelementptr inbounds i8,i8*%av,i64 16
%ax=bitcast i8*%aw to i8*(i8*,i8*)**
%ay=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ax,align 8
%az=bitcast i8*%av to i8**
%aA=load i8*,i8**%az,align 8
store i8*%aA,i8**%e,align 8
%aB=ptrtoint i8*%au to i64
%aC=call i8*@sml_alloc(i32 inreg 8)#0
%aD=getelementptr inbounds i8,i8*%aC,i64 -4
%aE=bitcast i8*%aD to i32*
store i32 8,i32*%aE,align 4
%aF=bitcast i8*%aC to i64*
store i64%aB,i64*%aF,align 4
%aG=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aH=call fastcc i8*%ay(i8*inreg%aG,i8*inreg%aC)
%aI=bitcast i8*%aH to i32*
%aJ=load i32,i32*%aI,align 4
%aK=icmp eq i32%aJ,0
br i1%aK,label%aU,label%aL
aL:
store i8*null,i8**%c,align 8
store i8*null,i8**%d,align 8
%aM=call fastcc i8*@_SMLFN16SMLSharp__Runtime9OS__SysErrE(i32 inreg 0)
store i8*%aM,i8**%c,align 8
%aN=call i8*@sml_alloc(i32 inreg 60)#0
%aO=getelementptr inbounds i8,i8*%aN,i64 -4
%aP=bitcast i8*%aO to i32*
store i32 1342177336,i32*%aP,align 4
%aQ=getelementptr inbounds i8,i8*%aN,i64 56
%aR=bitcast i8*%aQ to i32*
store i32 1,i32*%aR,align 4
%aS=load i8*,i8**%c,align 8
%aT=bitcast i8*%aN to i8**
store i8*%aS,i8**%aT,align 8
call void@sml_raise(i8*inreg%aN)#1
unreachable
aU:
%aV=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
store i8*null,i8**%e,align 8
br label%aW
aW:
%aX=phi i8*[%aV,%aU],[%ba,%a9]
%aY=icmp eq i8*%aX,null
br i1%aY,label%aZ,label%bb
aZ:
%a0=load i8*,i8**%e,align 8
%a1=icmp eq i8*%a0,null
br i1%a1,label%a2,label%a3
a2:
store i8*null,i8**%c,align 8
store i8*null,i8**%e,align 8
br label%dX
a3:
%a4=bitcast i8*%a0 to i8**
%a5=load i8*,i8**%a4,align 8
%a6=getelementptr inbounds i8,i8*%a0,i64 8
%a7=bitcast i8*%a6 to i8**
%a8=load i8*,i8**%a7,align 8
store i8*%a8,i8**%e,align 8
br label%a9
a9:
%ba=phi i8*[%a5,%a3],[%bJ,%bv],[%bg,%bR],[%cg,%b3],[%cw,%cv],[%bg,%cx],[%cP,%cy],[%dr,%dq],[%dF,%dE]
br label%aW
bb:
%bc=bitcast i8*%aX to i8**
%bd=load i8*,i8**%bc,align 8
%be=getelementptr inbounds i8,i8*%aX,i64 8
%bf=bitcast i8*%be to i8**
%bg=load i8*,i8**%bf,align 8
store i8*%bg,i8**%f,align 8
%bh=bitcast i8*%bd to i32*
%bi=load i32,i32*%bh,align 4
switch i32%bi,label%bj[
i32 6,label%ds
i32 3,label%cQ
i32 1,label%cy
i32 2,label%ch
i32 5,label%bT
i32 0,label%bK
i32 4,label%bv
]
bj:
store i8*null,i8**%c,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%f,align 8
invoke void@sml_matchcomp_bug()
to label%bk unwind label%dI
bk:
%bl=load i8*,i8**@_SMLZ5Match,align 8
store i8*%bl,i8**%c,align 8
%bm=call i8*@sml_alloc(i32 inreg 20)#0
%bn=getelementptr inbounds i8,i8*%bm,i64 -4
%bo=bitcast i8*%bn to i32*
store i32 1342177296,i32*%bo,align 4
%bp=load i8*,i8**%c,align 8
%bq=bitcast i8*%bm to i8**
store i8*%bp,i8**%bq,align 8
%br=getelementptr inbounds i8,i8*%bm,i64 8
%bs=bitcast i8*%br to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[66x i8]}>,<{[4x i8],i32,[66x i8]}>*@n,i64 0,i32 2,i64 0),i8**%bs,align 8
%bt=getelementptr inbounds i8,i8*%bm,i64 16
%bu=bitcast i8*%bt to i32*
store i32 3,i32*%bu,align 4
store i8*%bm,i8**%c,align 8
br label%dP
bv:
%bw=getelementptr inbounds i8,i8*%bd,i64 8
%bx=bitcast i8*%bw to i8**
%by=load i8*,i8**%bx,align 8
store i8*%by,i8**%g,align 8
%bz=call i8*@sml_alloc(i32 inreg 20)#0
%bA=getelementptr inbounds i8,i8*%bz,i64 -4
%bB=bitcast i8*%bA to i32*
store i32 1342177296,i32*%bB,align 4
%bC=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bD=bitcast i8*%bz to i8**
store i8*%bC,i8**%bD,align 8
%bE=load i8*,i8**%e,align 8
%bF=getelementptr inbounds i8,i8*%bz,i64 8
%bG=bitcast i8*%bF to i8**
store i8*%bE,i8**%bG,align 8
%bH=getelementptr inbounds i8,i8*%bz,i64 16
%bI=bitcast i8*%bH to i32*
store i32 3,i32*%bI,align 4
%bJ=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
store i8*%bz,i8**%e,align 8
br label%a9
bK:
%bL=load i8*,i8**%c,align 8
%bM=icmp eq i8*%bL,null
store i8*null,i8**%c,align 8
br i1%bM,label%bR,label%bN
bN:
%bO=getelementptr inbounds i8,i8*%bL,i64 8
%bP=bitcast i8*%bO to i8**
%bQ=load i8*,i8**%bP,align 8
br label%bR
bR:
%bS=phi i8*[%bQ,%bN],[null,%bK]
store i8*null,i8**%f,align 8
store i8*%bS,i8**%c,align 8
br label%a9
bT:
%bU=getelementptr inbounds i8,i8*%bd,i64 4
%bV=bitcast i8*%bU to i32*
%bW=load i32,i32*%bV,align 4
%bX=load i8*,i8**%c,align 8
%bY=icmp eq i8*%bX,null
br i1%bY,label%b3,label%bZ
bZ:
%b0=bitcast i8*%bX to i32*
%b1=load i32,i32*%b0,align 4
%b2=add nsw i32%b1,%bW
br label%b3
b3:
%b4=phi i32[%b2,%bZ],[%bW,%bT]
%b5=call i8*@sml_alloc(i32 inreg 20)#0
%b6=bitcast i8*%b5 to i32*
%b7=getelementptr inbounds i8,i8*%b5,i64 -4
%b8=bitcast i8*%b7 to i32*
store i32 1342177296,i32*%b8,align 4
%b9=getelementptr inbounds i8,i8*%b5,i64 4
%ca=bitcast i8*%b9 to i32*
store i32 0,i32*%ca,align 1
store i32%b4,i32*%b6,align 4
%cb=load i8*,i8**%c,align 8
%cc=getelementptr inbounds i8,i8*%b5,i64 8
%cd=bitcast i8*%cc to i8**
store i8*%cb,i8**%cd,align 8
%ce=getelementptr inbounds i8,i8*%b5,i64 16
%cf=bitcast i8*%ce to i32*
store i32 2,i32*%cf,align 4
%cg=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
store i8*%b5,i8**%c,align 8
br label%a9
ch:
%ci=getelementptr inbounds i8,i8*%bd,i64 8
%cj=bitcast i8*%ci to i8**
%ck=load i8*,i8**%cj,align 8
%cl=getelementptr inbounds i8,i8*%ck,i64 8
%cm=bitcast i8*%cl to i32*
%cn=load i32,i32*%cm,align 4
%co=icmp eq i32%cn,0
br i1%co,label%cx,label%cp
cp:
call void@sml_leave()#0
%cq=call i32@fputs(i8*getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@m,i64 0,i32 2,i64 0),i8*%au)
call void@sml_enter()#0
%cr=icmp sgt i32%cq,-1
br i1%cr,label%cv,label%cs
cs:
store i8*null,i8**%c,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%f,align 8
%ct=invoke fastcc i8*@_SMLFN16SMLSharp__Runtime9OS__SysErrE(i32 inreg 0)
to label%cu unwind label%dI
cu:
store i8*%ct,i8**%c,align 8
br label%dP
cv:
%cw=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
br label%a9
cx:
store i8*null,i8**%f,align 8
br label%a9
cy:
%cz=getelementptr inbounds i8,i8*%bd,i64 8
%cA=bitcast i8*%cz to i8**
%cB=load i8*,i8**%cA,align 8
%cC=getelementptr inbounds i8,i8*%cB,i64 8
%cD=bitcast i8*%cC to i8**
%cE=load i8*,i8**%cD,align 8
store i8*%cE,i8**%g,align 8
%cF=call i8*@sml_alloc(i32 inreg 20)#0
%cG=getelementptr inbounds i8,i8*%cF,i64 -4
%cH=bitcast i8*%cG to i32*
store i32 1342177296,i32*%cH,align 4
%cI=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%cJ=bitcast i8*%cF to i8**
store i8*%cI,i8**%cJ,align 8
%cK=load i8*,i8**%e,align 8
%cL=getelementptr inbounds i8,i8*%cF,i64 8
%cM=bitcast i8*%cL to i8**
store i8*%cK,i8**%cM,align 8
%cN=getelementptr inbounds i8,i8*%cF,i64 16
%cO=bitcast i8*%cN to i32*
store i32 3,i32*%cO,align 4
%cP=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
store i8*%cF,i8**%e,align 8
br label%a9
cQ:
%cR=load i8*,i8**%c,align 8
%cS=icmp eq i8*%cR,null
br i1%cS,label%cW,label%cT
cT:
%cU=bitcast i8*%cR to i32*
%cV=load i32,i32*%cU,align 4
br label%cW
cW:
%cX=phi i32[%cV,%cT],[0,%cQ]
%cY=call i8*@sml_alloc(i32 inreg 20)#0
%cZ=bitcast i8*%cY to i32*
%c0=getelementptr inbounds i8,i8*%cY,i64 -4
%c1=bitcast i8*%c0 to i32*
store i32 1342177296,i32*%c1,align 4
%c2=getelementptr inbounds i8,i8*%cY,i64 4
%c3=bitcast i8*%c2 to i32*
store i32 0,i32*%c3,align 1
store i32%cX,i32*%cZ,align 4
%c4=getelementptr inbounds i8,i8*%cY,i64 8
%c5=bitcast i8*%c4 to i8**
store i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@k,i64 0,i32 2)to i8*),i8**%c5,align 8
%c6=getelementptr inbounds i8,i8*%cY,i64 16
%c7=bitcast i8*%c6 to i32*
store i32 2,i32*%c7,align 4
%c8=invoke fastcc i8*@_SMLFN10CharVector8tabulateE(i8*inreg%cY)
to label%c9 unwind label%dG
c9:
store i8*%c8,i8**%g,align 8
%da=call i8*@sml_alloc(i32 inreg 20)#0
%db=getelementptr inbounds i8,i8*%da,i64 -4
%dc=bitcast i8*%db to i32*
store i32 1342177296,i32*%dc,align 4
%dd=bitcast i8*%da to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@l,i64 0,i32 2,i64 0),i8**%dd,align 8
%de=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%df=getelementptr inbounds i8,i8*%da,i64 8
%dg=bitcast i8*%df to i8**
store i8*%de,i8**%dg,align 8
%dh=getelementptr inbounds i8,i8*%da,i64 16
%di=bitcast i8*%dh to i32*
store i32 3,i32*%di,align 4
%dj=invoke fastcc i8*@_SMLFN6String1_ZE(i8*inreg%da)
to label%dk unwind label%dG
dk:
store i8*%dj,i8**%g,align 8
call void@sml_leave()#0
%dl=call i32@fputs(i8*%dj,i8*%au)
call void@sml_enter()#0
store i8*null,i8**%g,align 8
%dm=icmp sgt i32%dl,-1
br i1%dm,label%dq,label%dn
dn:
store i8*null,i8**%c,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%f,align 8
%do=invoke fastcc i8*@_SMLFN16SMLSharp__Runtime9OS__SysErrE(i32 inreg 0)
to label%dp unwind label%dI
dp:
store i8*%do,i8**%c,align 8
br label%dP
dq:
%dr=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
br label%a9
ds:
%dt=getelementptr inbounds i8,i8*%bd,i64 8
%du=bitcast i8*%dt to i8**
%dv=load i8*,i8**%du,align 8
%dw=getelementptr inbounds i8,i8*%dv,i64 8
%dx=bitcast i8*%dw to i8**
%dy=load i8*,i8**%dx,align 8
store i8*%dy,i8**%g,align 8
call void@sml_leave()#0
%dz=call i32@fputs(i8*%dy,i8*%au)
call void@sml_enter()#0
store i8*null,i8**%g,align 8
%dA=icmp sgt i32%dz,-1
br i1%dA,label%dE,label%dB
dB:
store i8*null,i8**%c,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%f,align 8
%dC=invoke fastcc i8*@_SMLFN16SMLSharp__Runtime9OS__SysErrE(i32 inreg 0)
to label%dD unwind label%dI
dD:
store i8*%dC,i8**%c,align 8
br label%dP
dE:
%dF=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
br label%a9
dG:
%dH=landingpad{i8*,i8*}
catch i8*null
br label%dK
dI:
%dJ=landingpad{i8*,i8*}
catch i8*null
br label%dK
dK:
%dL=phi{i8*,i8*}[%dH,%dG],[%dJ,%dI]
%dM=extractvalue{i8*,i8*}%dL,1
%dN=bitcast i8*%dM to i8**
%dO=load i8*,i8**%dN,align 8
store i8*null,i8**%e,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%g,align 8
store i8*%dO,i8**%c,align 8
br label%dP
dP:
%dQ=call i8*@sml_alloc(i32 inreg 12)#0
%dR=getelementptr inbounds i8,i8*%dQ,i64 -4
%dS=bitcast i8*%dR to i32*
store i32 1342177288,i32*%dS,align 4
%dT=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%dU=bitcast i8*%dQ to i8**
store i8*%dT,i8**%dU,align 8
%dV=getelementptr inbounds i8,i8*%dQ,i64 8
%dW=bitcast i8*%dV to i32*
store i32 1,i32*%dW,align 4
br label%dX
dX:
%dY=phi i8*[%dQ,%dP],[null,%a2]
store i8*%dY,i8**%c,align 8
call void@sml_leave()#0
%dZ=call i32@fclose(i8*%au)
call void@sml_enter()#0
%d0=load i8*,i8**%c,align 8
%d1=icmp eq i8*%d0,null
br i1%d1,label%ec,label%d2
d2:
%d3=bitcast i8*%d0 to i8**
store i8*null,i8**%d,align 8
%d4=load i8*,i8**%d3,align 8
store i8*%d4,i8**%c,align 8
%d5=call i8*@sml_alloc(i32 inreg 60)#0
%d6=getelementptr inbounds i8,i8*%d5,i64 -4
%d7=bitcast i8*%d6 to i32*
store i32 1342177336,i32*%d7,align 4
%d8=getelementptr inbounds i8,i8*%d5,i64 56
%d9=bitcast i8*%d8 to i32*
store i32 1,i32*%d9,align 4
%ea=load i8*,i8**%c,align 8
%eb=bitcast i8*%d5 to i8**
store i8*%ea,i8**%eb,align 8
call void@sml_raise(i8*inreg%d5)#1
unreachable
ec:
%ed=load i8*,i8**%d,align 8
ret i8*%ed
}
define fastcc i8*@_SMLFN8LLVMEmit4emitE(i8*inreg%a)local_unnamed_addr#2 gc"smlsharp"{
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
%j=load i8**,i8***bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[1x i8*]}>,<{[4x i8],i32,[1x i8*]}>*@_SML_gvarb79694c2fa396fe4_LLVMEmit,i64 0,i32 2,i64 0)to i8***),align 8
%k=load i8*,i8**%j,align 8
%l=tail call fastcc i8*@_SMLLLN8LLVMEmit4emitE_129(i8*inreg%k,i8*inreg%h)
ret i8*%l
}
define internal fastcc i8*@_SMLLLN8LLVMEmit5mergeE_131(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLLLN8LLVMEmit5mergeE_93(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLL7phiArgs_132(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
ret i8*null
}
define internal fastcc i8*@_SMLLL4phis_133(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLLL4phis_115(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLL6spaces_135(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=tail call i8*@sml_alloc(i32 inreg 1)#0
%d=getelementptr inbounds i8,i8*%c,i64 -4
%e=bitcast i8*%d to i32*
store i32 1,i32*%e,align 4
store i8 32,i8*%c,align 1
ret i8*%c
}
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
attributes#4={nounwind uwtable}
