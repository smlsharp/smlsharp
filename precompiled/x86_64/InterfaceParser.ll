@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN11ParserError10ParseErrorE=external local_unnamed_addr global i8*
@_SMLZN3Bug3BugE=external local_unnamed_addr global i8*
@_SMLZN7Control11allow8bitIdE=external local_unnamed_addr global i8*
@_SMLZN9Interface6Parser10ParseErrorE=external local_unnamed_addr global i8*
@_SMLZN9UserError10UserErrorsE=external local_unnamed_addr global i8*
@a=private unnamed_addr constant<{[4x i8],i32,[70x i8]}><{[4x i8]zeroinitializer,i32 -2147483578,[70x i8]c"src/compiler/compilePhases/parser/main/InterfaceParser.sml:20.51(554)\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN15InterfaceParser5setupE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN15InterfaceParser5setupE_49 to void(...)*),i32 -2147483647}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,[71x i8]}><{[4x i8]zeroinitializer,i32 -2147483577,[71x i8]c"src/compiler/compilePhases/parser/main/InterfaceParser.sml:42.35(1367)\00"}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,[22x i8]}><{[4x i8]zeroinitializer,i32 -2147483626,[22x i8]c"parse: aborted stream\00"}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[71x i8]}><{[4x i8]zeroinitializer,i32 -2147483577,[71x i8]c"src/compiler/compilePhases/parser/main/InterfaceParser.sml:47.25(1583)\00"}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,[71x i8]}><{[4x i8]zeroinitializer,i32 -2147483577,[71x i8]c"src/compiler/compilePhases/parser/main/InterfaceParser.sml:53.19(1763)\00"}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN15InterfaceParser5parseE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN15InterfaceParser5parseE_50 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN15InterfaceParser5setupE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@b,i64 0,i32 2)to i8*)
@_SMLZN15InterfaceParser5parseE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@g,i64 0,i32 2)to i8*)
@_SML_ftab9b3df51f850ccbaa_InterfaceParser=external global i8
@h=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i32@sml_personality(...)#0
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare void@sml_write(i8*inreg,i8**inreg,i8*inreg)local_unnamed_addr#0
declare i8*@_SMLFN12InterfaceLex16UserDeclarations7initArgE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN12InterfaceLex9makeLexerE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN9Interface6Parser10makeStreamE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN9Interface6Parser5parseE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN9UserError11createQueueE(i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN9UserError12enqueueErrorE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i32@_SMLFN9UserError17isEmptyErrorQueueE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN9UserError9getErrorsE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maineaa0aca8fbe4101a_Bug()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_mainadeb402e3568875f_UserError_ppg()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maina8c984cf5ab1458f_Control()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main46ef4cabdf69ec6b_interface_grm()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maine0137f5d62222932_interface_lex()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main40724fe7152bd191_ParserError_ppg()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_loadeaa0aca8fbe4101a_Bug(i8*)local_unnamed_addr
declare void@_SML_loadadeb402e3568875f_UserError_ppg(i8*)local_unnamed_addr
declare void@_SML_loada8c984cf5ab1458f_Control(i8*)local_unnamed_addr
declare void@_SML_load46ef4cabdf69ec6b_interface_grm(i8*)local_unnamed_addr
declare void@_SML_loade0137f5d62222932_interface_lex(i8*)local_unnamed_addr
declare void@_SML_load40724fe7152bd191_ParserError_ppg(i8*)local_unnamed_addr
define private void@_SML_tabb9b3df51f850ccbaa_InterfaceParser()#3{
unreachable
}
define void@_SML_load9b3df51f850ccbaa_InterfaceParser(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@h,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@h,align 1
tail call void@_SML_loadeaa0aca8fbe4101a_Bug(i8*%a)#0
tail call void@_SML_loadadeb402e3568875f_UserError_ppg(i8*%a)#0
tail call void@_SML_loada8c984cf5ab1458f_Control(i8*%a)#0
tail call void@_SML_load46ef4cabdf69ec6b_interface_grm(i8*%a)#0
tail call void@_SML_loade0137f5d62222932_interface_lex(i8*%a)#0
tail call void@_SML_load40724fe7152bd191_ParserError_ppg(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb9b3df51f850ccbaa_InterfaceParser,i8*@_SML_ftab9b3df51f850ccbaa_InterfaceParser,i8*null)#0
ret void
}
define void@_SML_main9b3df51f850ccbaa_InterfaceParser()local_unnamed_addr#2 gc"smlsharp"{
%a=load i8,i8*@h,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@h,align 1
tail call void@_SML_maineaa0aca8fbe4101a_Bug()#2
tail call void@_SML_mainadeb402e3568875f_UserError_ppg()#2
tail call void@_SML_maina8c984cf5ab1458f_Control()#2
tail call void@_SML_main46ef4cabdf69ec6b_interface_grm()#2
tail call void@_SML_maine0137f5d62222932_interface_lex()#2
tail call void@_SML_main40724fe7152bd191_ParserError_ppg()#2
br label%d
}
define internal fastcc void@_SMLLN15InterfaceParser10parseErrorE_36(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
store i8*%a,i8**%f,align 8
store i8*%b,i8**%c,align 8
%h=load atomic i32,i32*@sml_check_flag unordered,align 4
%i=icmp eq i32%h,0
br i1%i,label%j,label%l
j:
%k=bitcast i8*%a to i8**
br label%p
l:
call void@sml_check(i32 inreg%h)
%m=load i8*,i8**%c,align 8
%n=bitcast i8**%f to i8***
%o=load i8**,i8***%n,align 8
br label%p
p:
%q=phi i8**[%o,%l],[%k,%j]
%r=phi i8*[%m,%l],[%b,%j]
%s=getelementptr inbounds i8,i8*%r,i64 8
%t=bitcast i8*%s to i8**
%u=load i8*,i8**%t,align 8
store i8*%u,i8**%d,align 8
%v=getelementptr inbounds i8,i8*%r,i64 16
%w=bitcast i8*%v to i8**
%x=load i8*,i8**%w,align 8
store i8*%x,i8**%e,align 8
store i8*null,i8**%f,align 8
%y=load i8*,i8**%q,align 8
%z=call fastcc i8*@_SMLFN9UserError12enqueueErrorE(i8*inreg%y)
%A=getelementptr inbounds i8,i8*%z,i64 16
%B=bitcast i8*%A to i8*(i8*,i8*)**
%C=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%B,align 8
%D=bitcast i8*%z to i8**
%E=load i8*,i8**%D,align 8
store i8*%E,i8**%g,align 8
%F=call i8*@sml_alloc(i32 inreg 20)#0
%G=getelementptr inbounds i8,i8*%F,i64 -4
%H=bitcast i8*%G to i32*
store i32 1342177296,i32*%H,align 4
store i8*%F,i8**%f,align 8
%I=load i8*,i8**%d,align 8
%J=bitcast i8*%F to i8**
store i8*%I,i8**%J,align 8
%K=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%L=getelementptr inbounds i8,i8*%F,i64 8
%M=bitcast i8*%L to i8**
store i8*%K,i8**%M,align 8
%N=getelementptr inbounds i8,i8*%F,i64 16
%O=bitcast i8*%N to i32*
store i32 3,i32*%O,align 4
%P=load i8*,i8**@_SMLZN11ParserError10ParseErrorE,align 8
store i8*%P,i8**%d,align 8
%Q=bitcast i8**%c to i8***
%R=load i8**,i8***%Q,align 8
%S=load i8*,i8**%R,align 8
store i8*%S,i8**%c,align 8
%T=call i8*@sml_alloc(i32 inreg 28)#0
%U=getelementptr inbounds i8,i8*%T,i64 -4
%V=bitcast i8*%U to i32*
store i32 1342177304,i32*%V,align 4
store i8*%T,i8**%e,align 8
%W=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%X=bitcast i8*%T to i8**
store i8*%W,i8**%X,align 8
%Y=getelementptr inbounds i8,i8*%T,i64 8
%Z=bitcast i8*%Y to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[70x i8]}>,<{[4x i8],i32,[70x i8]}>*@a,i64 0,i32 2,i64 0),i8**%Z,align 8
%aa=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ab=getelementptr inbounds i8,i8*%T,i64 16
%ac=bitcast i8*%ab to i8**
store i8*%aa,i8**%ac,align 8
%ad=getelementptr inbounds i8,i8*%T,i64 24
%ae=bitcast i8*%ad to i32*
store i32 7,i32*%ae,align 4
%af=call i8*@sml_alloc(i32 inreg 20)#0
%ag=getelementptr inbounds i8,i8*%af,i64 -4
%ah=bitcast i8*%ag to i32*
store i32 1342177296,i32*%ah,align 4
%ai=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aj=bitcast i8*%af to i8**
store i8*%ai,i8**%aj,align 8
%ak=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%al=getelementptr inbounds i8,i8*%af,i64 8
%am=bitcast i8*%al to i8**
store i8*%ak,i8**%am,align 8
%an=getelementptr inbounds i8,i8*%af,i64 16
%ao=bitcast i8*%an to i32*
store i32 3,i32*%ao,align 4
%ap=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aq=call fastcc i8*%C(i8*inreg%ap,i8*inreg%af)
ret void
}
define fastcc i8*@_SMLFN15InterfaceParser5setupE(i8*inreg%a)#2 gc"smlsharp"{
n:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
store i8*%a,i8**%d,align 8
%h=load atomic i32,i32*@sml_check_flag unordered,align 4
%i=icmp eq i32%h,0
br i1%i,label%l,label%j
j:
call void@sml_check(i32 inreg%h)
%k=load i8*,i8**%d,align 8
br label%l
l:
%m=phi i8*[%k,%j],[%a,%n]
store i8*null,i8**%d,align 8
store i8*%m,i8**%g,align 8
%o=getelementptr inbounds i8,i8*%m,i64 8
%p=bitcast i8*%o to i8**
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%f,align 8
%r=call fastcc i8*@_SMLFN9UserError11createQueueE(i32 inreg 0)
store i8*%r,i8**%d,align 8
%s=bitcast i8**%b to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%s)
%t=bitcast i8**%c to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%t)
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%r,i8**%b,align 8
%u=call i8*@sml_alloc(i32 inreg 12)#0
%v=getelementptr inbounds i8,i8*%u,i64 -4
%w=bitcast i8*%v to i32*
store i32 1342177288,i32*%w,align 4
store i8*%u,i8**%c,align 8
%x=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%y=bitcast i8*%u to i8**
store i8*%x,i8**%y,align 8
%z=getelementptr inbounds i8,i8*%u,i64 8
%A=bitcast i8*%z to i32*
store i32 1,i32*%A,align 4
%B=call i8*@sml_alloc(i32 inreg 28)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177304,i32*%D,align 4
%E=load i8*,i8**%c,align 8
%F=bitcast i8*%B to i8**
store i8*%E,i8**%F,align 8
%G=getelementptr inbounds i8,i8*%B,i64 8
%H=bitcast i8*%G to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLLN15InterfaceParser10parseErrorE_36 to void(...)*),void(...)**%H,align 8
%I=getelementptr inbounds i8,i8*%B,i64 16
%J=bitcast i8*%I to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN15InterfaceParser10parseErrorE_47 to void(...)*),void(...)**%J,align 8
%K=getelementptr inbounds i8,i8*%B,i64 24
%L=bitcast i8*%K to i32*
store i32 -2147483647,i32*%L,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%s)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%t)
store i8*%B,i8**%e,align 8
%M=load i32*,i32**bitcast(i8**@_SMLZN7Control11allow8bitIdE to i32**),align 8
%N=load i32,i32*%M,align 4
%O=call i8*@sml_alloc(i32 inreg 28)#0
%P=bitcast i8*%O to i32*
%Q=getelementptr inbounds i8,i8*%O,i64 -4
%R=bitcast i8*%Q to i32*
store i32 1342177304,i32*%R,align 4
store i32%N,i32*%P,align 4
%S=getelementptr inbounds i8,i8*%O,i64 4
%T=bitcast i8*%S to i32*
store i32 1,i32*%T,align 4
%U=load i8*,i8**%e,align 8
%V=getelementptr inbounds i8,i8*%O,i64 8
%W=bitcast i8*%V to i8**
store i8*%U,i8**%W,align 8
%X=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%Y=getelementptr inbounds i8,i8*%O,i64 16
%Z=bitcast i8*%Y to i8**
store i8*%X,i8**%Z,align 8
%aa=getelementptr inbounds i8,i8*%O,i64 24
%ab=bitcast i8*%aa to i32*
store i32 6,i32*%ab,align 4
%ac=call fastcc i8*@_SMLFN12InterfaceLex16UserDeclarations7initArgE(i8*inreg%O)
store i8*%ac,i8**%f,align 8
%ad=bitcast i8**%g to i8***
%ae=load i8**,i8***%ad,align 8
store i8*null,i8**%g,align 8
%af=load i8*,i8**%ae,align 8
%ag=call fastcc i8*@_SMLFN12InterfaceLex9makeLexerE(i8*inreg%af)
%ah=getelementptr inbounds i8,i8*%ag,i64 16
%ai=bitcast i8*%ah to i8*(i8*,i8*)**
%aj=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ai,align 8
%ak=bitcast i8*%ag to i8**
%al=load i8*,i8**%ak,align 8
%am=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%an=call fastcc i8*%aj(i8*inreg%al,i8*inreg%am)
store i8*%an,i8**%f,align 8
%ao=call i8*@sml_alloc(i32 inreg 12)#0
%ap=getelementptr inbounds i8,i8*%ao,i64 -4
%aq=bitcast i8*%ap to i32*
store i32 1342177288,i32*%aq,align 4
%ar=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%as=bitcast i8*%ao to i8**
store i8*%ar,i8**%as,align 8
%at=getelementptr inbounds i8,i8*%ao,i64 8
%au=bitcast i8*%at to i32*
store i32 1,i32*%au,align 4
%av=call fastcc i8*@_SMLFN9Interface6Parser10makeStreamE(i8*inreg%ao)
store i8*%av,i8**%f,align 8
%aw=call i8*@sml_alloc(i32 inreg 8)#0
%ax=getelementptr inbounds i8,i8*%aw,i64 -4
%ay=bitcast i8*%ax to i32*
store i32 805306376,i32*%ay,align 4
store i8*%aw,i8**%g,align 8
%az=bitcast i8*%aw to i64*
store i64 0,i64*%az,align 1
%aA=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aB=bitcast i8*%aw to i8**
call void@sml_write(i8*inreg%aw,i8**inreg%aB,i8*inreg%aA)#0
%aC=call i8*@sml_alloc(i32 inreg 28)#0
%aD=getelementptr inbounds i8,i8*%aC,i64 -4
%aE=bitcast i8*%aD to i32*
store i32 1342177304,i32*%aE,align 4
%aF=load i8*,i8**%e,align 8
%aG=bitcast i8*%aC to i8**
store i8*%aF,i8**%aG,align 8
%aH=load i8*,i8**%d,align 8
%aI=getelementptr inbounds i8,i8*%aC,i64 8
%aJ=bitcast i8*%aI to i8**
store i8*%aH,i8**%aJ,align 8
%aK=load i8*,i8**%g,align 8
%aL=getelementptr inbounds i8,i8*%aC,i64 16
%aM=bitcast i8*%aL to i8**
store i8*%aK,i8**%aM,align 8
%aN=getelementptr inbounds i8,i8*%aC,i64 24
%aO=bitcast i8*%aN to i32*
store i32 7,i32*%aO,align 4
ret i8*%aC
}
define fastcc i8*@_SMLFN15InterfaceParser5parseE(i8*inreg%a)#2 gc"smlsharp"personality i32(...)*@sml_personality{
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
br i1%g,label%h,label%j
h:
%i=bitcast i8*%a to i8**
br label%m
j:
call void@sml_check(i32 inreg%f)
%k=bitcast i8**%b to i8***
%l=load i8**,i8***%k,align 8
br label%m
m:
%n=phi i8**[%l,%j],[%i,%h]
%o=load i8*,i8**%n,align 8
store i8*%o,i8**%d,align 8
%p=getelementptr inbounds i8*,i8**%n,i64 2
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%e,align 8
%r=getelementptr inbounds i8*,i8**%n,i64 1
%s=load i8*,i8**%r,align 8
%t=call fastcc i32@_SMLFN9UserError17isEmptyErrorQueueE(i8*inreg%s)
%u=icmp eq i32%t,0
br i1%u,label%v,label%P
v:
store i8*null,i8**%d,align 8
store i8*null,i8**%e,align 8
%w=load i8*,i8**@_SMLZN3Bug3BugE,align 8
store i8*%w,i8**%b,align 8
%x=call i8*@sml_alloc(i32 inreg 28)#0
%y=getelementptr inbounds i8,i8*%x,i64 -4
%z=bitcast i8*%y to i32*
store i32 1342177304,i32*%z,align 4
store i8*%x,i8**%c,align 8
%A=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%B=bitcast i8*%x to i8**
store i8*%A,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%x,i64 8
%D=bitcast i8*%C to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[71x i8]}>,<{[4x i8],i32,[71x i8]}>*@c,i64 0,i32 2,i64 0),i8**%D,align 8
%E=getelementptr inbounds i8,i8*%x,i64 16
%F=bitcast i8*%E to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[22x i8]}>,<{[4x i8],i32,[22x i8]}>*@d,i64 0,i32 2,i64 0),i8**%F,align 8
%G=getelementptr inbounds i8,i8*%x,i64 24
%H=bitcast i8*%G to i32*
store i32 7,i32*%H,align 4
%I=call i8*@sml_alloc(i32 inreg 60)#0
%J=getelementptr inbounds i8,i8*%I,i64 -4
%K=bitcast i8*%J to i32*
store i32 1342177336,i32*%K,align 4
%L=getelementptr inbounds i8,i8*%I,i64 56
%M=bitcast i8*%L to i32*
store i32 1,i32*%M,align 4
%N=load i8*,i8**%c,align 8
%O=bitcast i8*%I to i8**
store i8*%N,i8**%O,align 8
call void@sml_raise(i8*inreg%I)#1
unreachable
P:
%Q=bitcast i8**%e to i8***
%R=load i8**,i8***%Q,align 8
%S=load i8*,i8**%R,align 8
store i8*%S,i8**%c,align 8
%T=call i8*@sml_alloc(i32 inreg 36)#0
%U=getelementptr inbounds i8,i8*%T,i64 -4
%V=bitcast i8*%U to i32*
store i32 1342177312,i32*%V,align 4
call void@llvm.memset.p0i8.i64(i8*%T,i8 0,i64 24,i1 false)
%W=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%X=getelementptr inbounds i8,i8*%T,i64 8
%Y=bitcast i8*%X to i8**
store i8*%W,i8**%Y,align 8
%Z=getelementptr inbounds i8,i8*%T,i64 16
%aa=bitcast i8*%Z to i32*
store i32 15,i32*%aa,align 4
%ab=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ac=getelementptr inbounds i8,i8*%T,i64 24
%ad=bitcast i8*%ac to i8**
store i8*%ab,i8**%ad,align 8
%ae=getelementptr inbounds i8,i8*%T,i64 32
%af=bitcast i8*%ae to i32*
store i32 10,i32*%af,align 4
%ag=invoke fastcc i8*@_SMLFN9Interface6Parser5parseE(i8*inreg%T)
to label%ah unwind label%at
ah:
store i8*%ag,i8**%c,align 8
%ai=getelementptr inbounds i8,i8*%ag,i64 8
%aj=bitcast i8*%ai to i8**
%ak=load i8*,i8**%aj,align 8
%al=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%am=bitcast i8*%al to i8**
call void@sml_write(i8*inreg%al,i8**inreg%am,i8*inreg%ak)#0
%an=load i8*,i8**%b,align 8
%ao=getelementptr inbounds i8,i8*%an,i64 8
%ap=bitcast i8*%ao to i8**
%aq=load i8*,i8**%ap,align 8
%ar=call fastcc i32@_SMLFN9UserError17isEmptyErrorQueueE(i8*inreg%aq)
%as=icmp eq i32%ar,0
br i1%as,label%ba,label%bA
at:
%au=landingpad{i8*,i8*}
catch i8*null
%av=extractvalue{i8*,i8*}%au,1
%aw=bitcast i8*%av to i8**
%ax=load i8*,i8**%aw,align 8
store i8*null,i8**%e,align 8
store i8*%ax,i8**%c,align 8
%ay=bitcast i8*%ax to i8**
%az=load i8*,i8**%ay,align 8
%aA=load i8*,i8**@_SMLZN9Interface6Parser10ParseErrorE,align 8
%aB=icmp eq i8*%az,%aA
br i1%aB,label%aC,label%a2
aC:
%aD=load i8*,i8**@_SMLZN9UserError10UserErrorsE,align 8
store i8*%aD,i8**%c,align 8
%aE=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%aF=getelementptr inbounds i8,i8*%aE,i64 8
%aG=bitcast i8*%aF to i8**
%aH=load i8*,i8**%aG,align 8
%aI=call fastcc i8*@_SMLFN9UserError9getErrorsE(i8*inreg%aH)
store i8*%aI,i8**%b,align 8
%aJ=call i8*@sml_alloc(i32 inreg 28)#0
%aK=getelementptr inbounds i8,i8*%aJ,i64 -4
%aL=bitcast i8*%aK to i32*
store i32 1342177304,i32*%aL,align 4
store i8*%aJ,i8**%d,align 8
%aM=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aN=bitcast i8*%aJ to i8**
store i8*%aM,i8**%aN,align 8
%aO=getelementptr inbounds i8,i8*%aJ,i64 8
%aP=bitcast i8*%aO to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[71x i8]}>,<{[4x i8],i32,[71x i8]}>*@e,i64 0,i32 2,i64 0),i8**%aP,align 8
%aQ=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%aR=getelementptr inbounds i8,i8*%aJ,i64 16
%aS=bitcast i8*%aR to i8**
store i8*%aQ,i8**%aS,align 8
%aT=getelementptr inbounds i8,i8*%aJ,i64 24
%aU=bitcast i8*%aT to i32*
store i32 7,i32*%aU,align 4
%aV=call i8*@sml_alloc(i32 inreg 60)#0
%aW=getelementptr inbounds i8,i8*%aV,i64 -4
%aX=bitcast i8*%aW to i32*
store i32 1342177336,i32*%aX,align 4
%aY=getelementptr inbounds i8,i8*%aV,i64 56
%aZ=bitcast i8*%aY to i32*
store i32 1,i32*%aZ,align 4
%a0=load i8*,i8**%d,align 8
%a1=bitcast i8*%aV to i8**
store i8*%a0,i8**%a1,align 8
call void@sml_raise(i8*inreg%aV)#1
unreachable
a2:
store i8*null,i8**%b,align 8
%a3=call i8*@sml_alloc(i32 inreg 60)#0
%a4=getelementptr inbounds i8,i8*%a3,i64 -4
%a5=bitcast i8*%a4 to i32*
store i32 1342177336,i32*%a5,align 4
%a6=getelementptr inbounds i8,i8*%a3,i64 56
%a7=bitcast i8*%a6 to i32*
store i32 1,i32*%a7,align 4
%a8=load i8*,i8**%c,align 8
%a9=bitcast i8*%a3 to i8**
store i8*%a8,i8**%a9,align 8
call void@sml_raise(i8*inreg%a3)#1
unreachable
ba:
%bb=load i8*,i8**@_SMLZN9UserError10UserErrorsE,align 8
store i8*%bb,i8**%c,align 8
%bc=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%bd=getelementptr inbounds i8,i8*%bc,i64 8
%be=bitcast i8*%bd to i8**
%bf=load i8*,i8**%be,align 8
%bg=call fastcc i8*@_SMLFN9UserError9getErrorsE(i8*inreg%bf)
store i8*%bg,i8**%b,align 8
%bh=call i8*@sml_alloc(i32 inreg 28)#0
%bi=getelementptr inbounds i8,i8*%bh,i64 -4
%bj=bitcast i8*%bi to i32*
store i32 1342177304,i32*%bj,align 4
store i8*%bh,i8**%d,align 8
%bk=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bl=bitcast i8*%bh to i8**
store i8*%bk,i8**%bl,align 8
%bm=getelementptr inbounds i8,i8*%bh,i64 8
%bn=bitcast i8*%bm to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[71x i8]}>,<{[4x i8],i32,[71x i8]}>*@f,i64 0,i32 2,i64 0),i8**%bn,align 8
%bo=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%bp=getelementptr inbounds i8,i8*%bh,i64 16
%bq=bitcast i8*%bp to i8**
store i8*%bo,i8**%bq,align 8
%br=getelementptr inbounds i8,i8*%bh,i64 24
%bs=bitcast i8*%br to i32*
store i32 7,i32*%bs,align 4
%bt=call i8*@sml_alloc(i32 inreg 60)#0
%bu=getelementptr inbounds i8,i8*%bt,i64 -4
%bv=bitcast i8*%bu to i32*
store i32 1342177336,i32*%bv,align 4
%bw=getelementptr inbounds i8,i8*%bt,i64 56
%bx=bitcast i8*%bw to i32*
store i32 1,i32*%bx,align 4
%by=load i8*,i8**%d,align 8
%bz=bitcast i8*%bt to i8**
store i8*%by,i8**%bz,align 8
call void@sml_raise(i8*inreg%bt)#1
unreachable
bA:
%bB=bitcast i8**%c to i8***
%bC=load i8**,i8***%bB,align 8
%bD=load i8*,i8**%bC,align 8
ret i8*%bD
}
define internal fastcc i8*@_SMLLN15InterfaceParser10parseErrorE_47(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
tail call fastcc void@_SMLLN15InterfaceParser10parseErrorE_36(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLN15InterfaceParser5setupE_49(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN15InterfaceParser5setupE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLN15InterfaceParser5parseE_50(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN15InterfaceParser5parseE(i8*inreg%b)
ret i8*%c
}
declare void@llvm.lifetime.start.p0i8(i64,i8*)#0
declare void@llvm.lifetime.end.p0i8(i64,i8*)#0
declare void@llvm.memset.p0i8.i64(i8*,i8,i64,i1)#0
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
