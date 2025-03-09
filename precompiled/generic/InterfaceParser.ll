@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN11ParserError10ParseErrorE=external local_unnamed_addr global i8*
@_SMLZN3Bug3BugE=external local_unnamed_addr global i8*
@_SMLZN7Control11allow8bitIdE=external local_unnamed_addr global i8*
@_SMLZN9Interface6Parser10ParseErrorE=external local_unnamed_addr global i8*
@_SMLZN9UserError10UserErrorsE=external local_unnamed_addr global i8*
@a=private unnamed_addr constant<{[4x i8],i32,[70x i8]}><{[4x i8]zeroinitializer,i32 -2147483578,[70x i8]c"src/compiler/compilePhases/parser/main/InterfaceParser.sml:20.51(554)\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN15InterfaceParser5setupE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN15InterfaceParser5setupE_46 to void(...)*),i32 -2147483647}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,[71x i8]}><{[4x i8]zeroinitializer,i32 -2147483577,[71x i8]c"src/compiler/compilePhases/parser/main/InterfaceParser.sml:42.35(1367)\00"}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,[22x i8]}><{[4x i8]zeroinitializer,i32 -2147483626,[22x i8]c"parse: aborted stream\00"}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[71x i8]}><{[4x i8]zeroinitializer,i32 -2147483577,[71x i8]c"src/compiler/compilePhases/parser/main/InterfaceParser.sml:47.25(1583)\00"}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,[71x i8]}><{[4x i8]zeroinitializer,i32 -2147483577,[71x i8]c"src/compiler/compilePhases/parser/main/InterfaceParser.sml:53.19(1763)\00"}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN15InterfaceParser5parseE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN15InterfaceParser5parseE_47 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN15InterfaceParser5setupE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@b,i64 0,i32 2)to i8*)
@_SMLZN15InterfaceParser5parseE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@g,i64 0,i32 2)to i8*)
@_SML_ftababa4fad986a277bc_InterfaceParser=external global i8
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
declare void@_SML_main1a3c7df0529f4f3d_Control()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_mainfc945e814b73aec9_interface_grm()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main76e66750c46dd9d2_interface_lex()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main40724fe7152bd191_ParserError_ppg()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_loadeaa0aca8fbe4101a_Bug(i8*)local_unnamed_addr
declare void@_SML_loadadeb402e3568875f_UserError_ppg(i8*)local_unnamed_addr
declare void@_SML_load1a3c7df0529f4f3d_Control(i8*)local_unnamed_addr
declare void@_SML_loadfc945e814b73aec9_interface_grm(i8*)local_unnamed_addr
declare void@_SML_load76e66750c46dd9d2_interface_lex(i8*)local_unnamed_addr
declare void@_SML_load40724fe7152bd191_ParserError_ppg(i8*)local_unnamed_addr
define private void@_SML_tabbaba4fad986a277bc_InterfaceParser()#3{
unreachable
}
define void@_SML_loadaba4fad986a277bc_InterfaceParser(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@h,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@h,align 1
tail call void@_SML_loadeaa0aca8fbe4101a_Bug(i8*%a)#0
tail call void@_SML_loadadeb402e3568875f_UserError_ppg(i8*%a)#0
tail call void@_SML_load1a3c7df0529f4f3d_Control(i8*%a)#0
tail call void@_SML_loadfc945e814b73aec9_interface_grm(i8*%a)#0
tail call void@_SML_load76e66750c46dd9d2_interface_lex(i8*%a)#0
tail call void@_SML_load40724fe7152bd191_ParserError_ppg(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbaba4fad986a277bc_InterfaceParser,i8*@_SML_ftababa4fad986a277bc_InterfaceParser,i8*null)#0
ret void
}
define void@_SML_mainaba4fad986a277bc_InterfaceParser()local_unnamed_addr#2 gc"smlsharp"{
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
tail call void@_SML_main1a3c7df0529f4f3d_Control()#2
tail call void@_SML_mainfc945e814b73aec9_interface_grm()#2
tail call void@_SML_main76e66750c46dd9d2_interface_lex()#2
tail call void@_SML_main40724fe7152bd191_ParserError_ppg()#2
br label%d
}
define internal fastcc void@_SMLLL7errorFn_36(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
%s=bitcast i8*%r to i8**
%t=load i8*,i8**%s,align 8
store i8*%t,i8**%c,align 8
%u=getelementptr inbounds i8,i8*%r,i64 8
%v=bitcast i8*%u to i8**
%w=load i8*,i8**%v,align 8
store i8*%w,i8**%d,align 8
%x=getelementptr inbounds i8,i8*%r,i64 16
%y=bitcast i8*%x to i8**
%z=load i8*,i8**%y,align 8
store i8*%z,i8**%e,align 8
store i8*null,i8**%f,align 8
%A=load i8*,i8**%q,align 8
%B=call fastcc i8*@_SMLFN9UserError12enqueueErrorE(i8*inreg%A)
%C=getelementptr inbounds i8,i8*%B,i64 16
%D=bitcast i8*%C to i8*(i8*,i8*)**
%E=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%D,align 8
%F=bitcast i8*%B to i8**
%G=load i8*,i8**%F,align 8
store i8*%G,i8**%g,align 8
%H=call i8*@sml_alloc(i32 inreg 20)#0
%I=getelementptr inbounds i8,i8*%H,i64 -4
%J=bitcast i8*%I to i32*
store i32 1342177296,i32*%J,align 4
store i8*%H,i8**%f,align 8
%K=load i8*,i8**%d,align 8
%L=bitcast i8*%H to i8**
store i8*%K,i8**%L,align 8
%M=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%N=getelementptr inbounds i8,i8*%H,i64 8
%O=bitcast i8*%N to i8**
store i8*%M,i8**%O,align 8
%P=getelementptr inbounds i8,i8*%H,i64 16
%Q=bitcast i8*%P to i32*
store i32 3,i32*%Q,align 4
%R=load i8*,i8**@_SMLZN11ParserError10ParseErrorE,align 8
store i8*%R,i8**%d,align 8
%S=call i8*@sml_alloc(i32 inreg 28)#0
%T=getelementptr inbounds i8,i8*%S,i64 -4
%U=bitcast i8*%T to i32*
store i32 1342177304,i32*%U,align 4
store i8*%S,i8**%e,align 8
%V=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%W=bitcast i8*%S to i8**
store i8*%V,i8**%W,align 8
%X=getelementptr inbounds i8,i8*%S,i64 8
%Y=bitcast i8*%X to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[70x i8]}>,<{[4x i8],i32,[70x i8]}>*@a,i64 0,i32 2,i64 0),i8**%Y,align 8
%Z=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aa=getelementptr inbounds i8,i8*%S,i64 16
%ab=bitcast i8*%aa to i8**
store i8*%Z,i8**%ab,align 8
%ac=getelementptr inbounds i8,i8*%S,i64 24
%ad=bitcast i8*%ac to i32*
store i32 7,i32*%ad,align 4
%ae=call i8*@sml_alloc(i32 inreg 20)#0
%af=getelementptr inbounds i8,i8*%ae,i64 -4
%ag=bitcast i8*%af to i32*
store i32 1342177296,i32*%ag,align 4
%ah=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ai=bitcast i8*%ae to i8**
store i8*%ah,i8**%ai,align 8
%aj=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ak=getelementptr inbounds i8,i8*%ae,i64 8
%al=bitcast i8*%ak to i8**
store i8*%aj,i8**%al,align 8
%am=getelementptr inbounds i8,i8*%ae,i64 16
%an=bitcast i8*%am to i32*
store i32 3,i32*%an,align 4
%ao=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%ap=call fastcc i8*%E(i8*inreg%ao,i8*inreg%ae)
ret void
}
define fastcc i8*@_SMLFN15InterfaceParser5setupE(i8*inreg%a)#2 gc"smlsharp"{
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
%p=getelementptr inbounds i8,i8*%l,i64 8
%q=bitcast i8*%p to i8**
%r=load i8*,i8**%q,align 8
store i8*%r,i8**%c,align 8
%s=call fastcc i8*@_SMLFN9UserError11createQueueE(i32 inreg 0)
store i8*%s,i8**%d,align 8
%t=call i8*@sml_alloc(i32 inreg 12)#0
%u=getelementptr inbounds i8,i8*%t,i64 -4
%v=bitcast i8*%u to i32*
store i32 1342177288,i32*%v,align 4
store i8*%t,i8**%e,align 8
%w=load i8*,i8**%d,align 8
%x=bitcast i8*%t to i8**
store i8*%w,i8**%x,align 8
%y=getelementptr inbounds i8,i8*%t,i64 8
%z=bitcast i8*%y to i32*
store i32 1,i32*%z,align 4
%A=call i8*@sml_alloc(i32 inreg 28)#0
%B=getelementptr inbounds i8,i8*%A,i64 -4
%C=bitcast i8*%B to i32*
store i32 1342177304,i32*%C,align 4
store i8*%A,i8**%f,align 8
%D=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%E=bitcast i8*%A to i8**
store i8*%D,i8**%E,align 8
%F=getelementptr inbounds i8,i8*%A,i64 8
%G=bitcast i8*%F to void(...)**
store void(...)*bitcast(void(i8*,i8*)*@_SMLLL7errorFn_36 to void(...)*),void(...)**%G,align 8
%H=getelementptr inbounds i8,i8*%A,i64 16
%I=bitcast i8*%H to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL7errorFn_45 to void(...)*),void(...)**%I,align 8
%J=getelementptr inbounds i8,i8*%A,i64 24
%K=bitcast i8*%J to i32*
store i32 -2147483647,i32*%K,align 4
%L=load i32*,i32**bitcast(i8**@_SMLZN7Control11allow8bitIdE to i32**),align 8
%M=load i32,i32*%L,align 4
%N=call i8*@sml_alloc(i32 inreg 28)#0
%O=bitcast i8*%N to i32*
%P=getelementptr inbounds i8,i8*%N,i64 -4
%Q=bitcast i8*%P to i32*
store i32 1342177304,i32*%Q,align 4
store i32%M,i32*%O,align 4
%R=getelementptr inbounds i8,i8*%N,i64 4
%S=bitcast i8*%R to i32*
store i32 1,i32*%S,align 4
%T=load i8*,i8**%f,align 8
%U=getelementptr inbounds i8,i8*%N,i64 8
%V=bitcast i8*%U to i8**
store i8*%T,i8**%V,align 8
%W=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%X=getelementptr inbounds i8,i8*%N,i64 16
%Y=bitcast i8*%X to i8**
store i8*%W,i8**%Y,align 8
%Z=getelementptr inbounds i8,i8*%N,i64 24
%aa=bitcast i8*%Z to i32*
store i32 6,i32*%aa,align 4
%ab=call fastcc i8*@_SMLFN12InterfaceLex16UserDeclarations7initArgE(i8*inreg%N)
store i8*%ab,i8**%c,align 8
%ac=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%ad=call fastcc i8*@_SMLFN12InterfaceLex9makeLexerE(i8*inreg%ac)
%ae=getelementptr inbounds i8,i8*%ad,i64 16
%af=bitcast i8*%ae to i8*(i8*,i8*)**
%ag=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%af,align 8
%ah=bitcast i8*%ad to i8**
%ai=load i8*,i8**%ah,align 8
%aj=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ak=call fastcc i8*%ag(i8*inreg%ai,i8*inreg%aj)
store i8*%ak,i8**%b,align 8
%al=call i8*@sml_alloc(i32 inreg 12)#0
%am=getelementptr inbounds i8,i8*%al,i64 -4
%an=bitcast i8*%am to i32*
store i32 1342177288,i32*%an,align 4
%ao=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%ap=bitcast i8*%al to i8**
store i8*%ao,i8**%ap,align 8
%aq=getelementptr inbounds i8,i8*%al,i64 8
%ar=bitcast i8*%aq to i32*
store i32 1,i32*%ar,align 4
%as=call fastcc i8*@_SMLFN9Interface6Parser10makeStreamE(i8*inreg%al)
store i8*%as,i8**%b,align 8
%at=call i8*@sml_alloc(i32 inreg 8)#0
%au=getelementptr inbounds i8,i8*%at,i64 -4
%av=bitcast i8*%au to i32*
store i32 805306376,i32*%av,align 4
store i8*%at,i8**%c,align 8
%aw=bitcast i8*%at to i64*
store i64 0,i64*%aw,align 1
%ax=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%ay=bitcast i8*%at to i8**
call void@sml_write(i8*inreg%at,i8**inreg%ay,i8*inreg%ax)#0
%az=call i8*@sml_alloc(i32 inreg 28)#0
%aA=getelementptr inbounds i8,i8*%az,i64 -4
%aB=bitcast i8*%aA to i32*
store i32 1342177304,i32*%aB,align 4
%aC=load i8*,i8**%f,align 8
%aD=bitcast i8*%az to i8**
store i8*%aC,i8**%aD,align 8
%aE=load i8*,i8**%d,align 8
%aF=getelementptr inbounds i8,i8*%az,i64 8
%aG=bitcast i8*%aF to i8**
store i8*%aE,i8**%aG,align 8
%aH=load i8*,i8**%c,align 8
%aI=getelementptr inbounds i8,i8*%az,i64 16
%aJ=bitcast i8*%aI to i8**
store i8*%aH,i8**%aJ,align 8
%aK=getelementptr inbounds i8,i8*%az,i64 24
%aL=bitcast i8*%aK to i32*
store i32 7,i32*%aL,align 4
ret i8*%az
}
define fastcc i8*@_SMLFN15InterfaceParser5parseE(i8*inreg%a)#2 gc"smlsharp"personality i32(...)*@sml_personality{
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
%r=getelementptr inbounds i8,i8*%k,i64 16
%s=bitcast i8*%r to i8**
%t=load i8*,i8**%s,align 8
store i8*%t,i8**%d,align 8
%u=call fastcc i32@_SMLFN9UserError17isEmptyErrorQueueE(i8*inreg%q)
%v=icmp eq i32%u,0
br i1%v,label%w,label%Q
w:
store i8*null,i8**%c,align 8
store i8*null,i8**%d,align 8
%x=load i8*,i8**@_SMLZN3Bug3BugE,align 8
store i8*%x,i8**%b,align 8
%y=call i8*@sml_alloc(i32 inreg 28)#0
%z=getelementptr inbounds i8,i8*%y,i64 -4
%A=bitcast i8*%z to i32*
store i32 1342177304,i32*%A,align 4
store i8*%y,i8**%c,align 8
%B=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%C=bitcast i8*%y to i8**
store i8*%B,i8**%C,align 8
%D=getelementptr inbounds i8,i8*%y,i64 8
%E=bitcast i8*%D to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[71x i8]}>,<{[4x i8],i32,[71x i8]}>*@c,i64 0,i32 2,i64 0),i8**%E,align 8
%F=getelementptr inbounds i8,i8*%y,i64 16
%G=bitcast i8*%F to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[22x i8]}>,<{[4x i8],i32,[22x i8]}>*@d,i64 0,i32 2,i64 0),i8**%G,align 8
%H=getelementptr inbounds i8,i8*%y,i64 24
%I=bitcast i8*%H to i32*
store i32 7,i32*%I,align 4
%J=call i8*@sml_alloc(i32 inreg 60)#0
%K=getelementptr inbounds i8,i8*%J,i64 -4
%L=bitcast i8*%K to i32*
store i32 1342177336,i32*%L,align 4
%M=getelementptr inbounds i8,i8*%J,i64 56
%N=bitcast i8*%M to i32*
store i32 1,i32*%N,align 4
%O=load i8*,i8**%c,align 8
%P=bitcast i8*%J to i8**
store i8*%O,i8**%P,align 8
call void@sml_raise(i8*inreg%J)#1
unreachable
Q:
%R=bitcast i8**%d to i8***
%S=load i8**,i8***%R,align 8
%T=load i8*,i8**%S,align 8
store i8*%T,i8**%e,align 8
%U=call i8*@sml_alloc(i32 inreg 36)#0
%V=getelementptr inbounds i8,i8*%U,i64 -4
%W=bitcast i8*%V to i32*
store i32 1342177312,i32*%W,align 4
call void@llvm.memset.p0i8.i64(i8*%U,i8 0,i64 24,i1 false)
%X=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%Y=getelementptr inbounds i8,i8*%U,i64 8
%Z=bitcast i8*%Y to i8**
store i8*%X,i8**%Z,align 8
%aa=getelementptr inbounds i8,i8*%U,i64 16
%ab=bitcast i8*%aa to i32*
store i32 15,i32*%ab,align 4
%ac=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ad=getelementptr inbounds i8,i8*%U,i64 24
%ae=bitcast i8*%ad to i8**
store i8*%ac,i8**%ae,align 8
%af=getelementptr inbounds i8,i8*%U,i64 32
%ag=bitcast i8*%af to i32*
store i32 10,i32*%ag,align 4
%ah=invoke fastcc i8*@_SMLFN9Interface6Parser5parseE(i8*inreg%U)
to label%aW unwind label%ai
ai:
%aj=landingpad{i8*,i8*}
catch i8*null
%ak=extractvalue{i8*,i8*}%aj,1
%al=bitcast i8*%ak to i8**
%am=load i8*,i8**%al,align 8
store i8*null,i8**%d,align 8
store i8*%am,i8**%b,align 8
%an=bitcast i8*%am to i8**
%ao=load i8*,i8**%an,align 8
%ap=load i8*,i8**@_SMLZN9Interface6Parser10ParseErrorE,align 8
%aq=icmp eq i8*%ao,%ap
br i1%aq,label%ar,label%aO
ar:
%as=load i8*,i8**@_SMLZN9UserError10UserErrorsE,align 8
store i8*%as,i8**%b,align 8
%at=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%au=call fastcc i8*@_SMLFN9UserError9getErrorsE(i8*inreg%at)
store i8*%au,i8**%c,align 8
%av=call i8*@sml_alloc(i32 inreg 28)#0
%aw=getelementptr inbounds i8,i8*%av,i64 -4
%ax=bitcast i8*%aw to i32*
store i32 1342177304,i32*%ax,align 4
store i8*%av,i8**%d,align 8
%ay=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%az=bitcast i8*%av to i8**
store i8*%ay,i8**%az,align 8
%aA=getelementptr inbounds i8,i8*%av,i64 8
%aB=bitcast i8*%aA to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[71x i8]}>,<{[4x i8],i32,[71x i8]}>*@e,i64 0,i32 2,i64 0),i8**%aB,align 8
%aC=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aD=getelementptr inbounds i8,i8*%av,i64 16
%aE=bitcast i8*%aD to i8**
store i8*%aC,i8**%aE,align 8
%aF=getelementptr inbounds i8,i8*%av,i64 24
%aG=bitcast i8*%aF to i32*
store i32 7,i32*%aG,align 4
%aH=call i8*@sml_alloc(i32 inreg 60)#0
%aI=getelementptr inbounds i8,i8*%aH,i64 -4
%aJ=bitcast i8*%aI to i32*
store i32 1342177336,i32*%aJ,align 4
%aK=getelementptr inbounds i8,i8*%aH,i64 56
%aL=bitcast i8*%aK to i32*
store i32 1,i32*%aL,align 4
%aM=load i8*,i8**%d,align 8
%aN=bitcast i8*%aH to i8**
store i8*%aM,i8**%aN,align 8
call void@sml_raise(i8*inreg%aH)#1
unreachable
aO:
store i8*null,i8**%c,align 8
%aP=call i8*@sml_alloc(i32 inreg 60)#0
%aQ=getelementptr inbounds i8,i8*%aP,i64 -4
%aR=bitcast i8*%aQ to i32*
store i32 1342177336,i32*%aR,align 4
%aS=getelementptr inbounds i8,i8*%aP,i64 56
%aT=bitcast i8*%aS to i32*
store i32 1,i32*%aT,align 4
%aU=load i8*,i8**%b,align 8
%aV=bitcast i8*%aP to i8**
store i8*%aU,i8**%aV,align 8
call void@sml_raise(i8*inreg%aP)#1
unreachable
aW:
%aX=bitcast i8*%ah to i8**
%aY=load i8*,i8**%aX,align 8
store i8*%aY,i8**%b,align 8
%aZ=getelementptr inbounds i8,i8*%ah,i64 8
%a0=bitcast i8*%aZ to i8**
%a1=load i8*,i8**%a0,align 8
%a2=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%a3=bitcast i8*%a2 to i8**
call void@sml_write(i8*inreg%a2,i8**inreg%a3,i8*inreg%a1)#0
%a4=load i8*,i8**%c,align 8
%a5=call fastcc i32@_SMLFN9UserError17isEmptyErrorQueueE(i8*inreg%a4)
%a6=icmp eq i32%a5,0
br i1%a6,label%a7,label%bu
a7:
%a8=load i8*,i8**@_SMLZN9UserError10UserErrorsE,align 8
store i8*%a8,i8**%b,align 8
%a9=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ba=call fastcc i8*@_SMLFN9UserError9getErrorsE(i8*inreg%a9)
store i8*%ba,i8**%c,align 8
%bb=call i8*@sml_alloc(i32 inreg 28)#0
%bc=getelementptr inbounds i8,i8*%bb,i64 -4
%bd=bitcast i8*%bc to i32*
store i32 1342177304,i32*%bd,align 4
store i8*%bb,i8**%d,align 8
%be=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%bf=bitcast i8*%bb to i8**
store i8*%be,i8**%bf,align 8
%bg=getelementptr inbounds i8,i8*%bb,i64 8
%bh=bitcast i8*%bg to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[71x i8]}>,<{[4x i8],i32,[71x i8]}>*@f,i64 0,i32 2,i64 0),i8**%bh,align 8
%bi=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%bj=getelementptr inbounds i8,i8*%bb,i64 16
%bk=bitcast i8*%bj to i8**
store i8*%bi,i8**%bk,align 8
%bl=getelementptr inbounds i8,i8*%bb,i64 24
%bm=bitcast i8*%bl to i32*
store i32 7,i32*%bm,align 4
%bn=call i8*@sml_alloc(i32 inreg 60)#0
%bo=getelementptr inbounds i8,i8*%bn,i64 -4
%bp=bitcast i8*%bo to i32*
store i32 1342177336,i32*%bp,align 4
%bq=getelementptr inbounds i8,i8*%bn,i64 56
%br=bitcast i8*%bq to i32*
store i32 1,i32*%br,align 4
%bs=load i8*,i8**%d,align 8
%bt=bitcast i8*%bn to i8**
store i8*%bs,i8**%bt,align 8
call void@sml_raise(i8*inreg%bn)#1
unreachable
bu:
%bv=load i8*,i8**%b,align 8
ret i8*%bv
}
define internal fastcc i8*@_SMLLL7errorFn_45(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
tail call fastcc void@_SMLLL7errorFn_36(i8*inreg%a,i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLLN15InterfaceParser5setupE_46(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN15InterfaceParser5setupE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN15InterfaceParser5parseE_47(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN15InterfaceParser5parseE(i8*inreg%b)
ret i8*%c
}
declare void@llvm.memset.p0i8.i64(i8*,i8,i64,i1)#0
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
