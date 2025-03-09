@sml_check_flag=external local_unnamed_addr global i32
@_SMLZ5Match=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[13x i8]}><{[4x i8]zeroinitializer,i32 -2147483635,[13x i8]c"ForeachArray\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[13x i8]}>,<{[4x i8],i32,[13x i8]}>*@a,i32 0,i32 0,i32 0),i32 8),i8*null,i32 3}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[13x i8]}>,<{[4x i8],i32,[13x i8]}>*@a,i32 0,i32 0,i32 0),i32 8),i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@b,i32 0,i32 0,i32 0),i32 8),i32 3}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,[12x i8]}><{[4x i8]zeroinitializer,i32 -2147483636,[12x i8]c"ForeachData\00"}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[12x i8]}>,<{[4x i8],i32,[12x i8]}>*@d,i32 0,i32 0,i32 0),i32 8),i8*null,i32 3}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[12x i8]}>,<{[4x i8],i32,[12x i8]}>*@d,i32 0,i32 0,i32 0),i32 8),i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@e,i32 0,i32 0,i32 0),i32 8),i32 3}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,[74x i8]}><{[4x i8]zeroinitializer,i32 -2147483574,[74x i8]c"src/compiler/compilePhases/elaborate/main/ElaborateForeach.sml:51.6(1201)\00"}>,align 8
@h=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN16ElaborateForeach12elaborateExpE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_63 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN16ElaborateForeach12elaborateExpE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@h,i64 0,i32 2)to i8*)
@_SML_ftab540ed99f009ba890_ElaborateForeach=external global i8
@i=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_matchcomp_bug()local_unnamed_addr
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare i8*@_SMLFN11RecordLabel9tupleListE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List3mapE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN6Symbol12mkLongsymbolE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main03d87556ec7f64b2_List()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main89b8631430c545af_Symbol()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maina142c315f12317c0_RecordLabel()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load03d87556ec7f64b2_List(i8*)local_unnamed_addr
declare void@_SML_load89b8631430c545af_Symbol(i8*)local_unnamed_addr
declare void@_SML_loada142c315f12317c0_RecordLabel(i8*)local_unnamed_addr
define private void@_SML_tabb540ed99f009ba890_ElaborateForeach()#3{
unreachable
}
define void@_SML_load540ed99f009ba890_ElaborateForeach(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@i,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@i,align 1
tail call void@_SML_load03d87556ec7f64b2_List(i8*%a)#0
tail call void@_SML_load89b8631430c545af_Symbol(i8*%a)#0
tail call void@_SML_loada142c315f12317c0_RecordLabel(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb540ed99f009ba890_ElaborateForeach,i8*@_SML_ftab540ed99f009ba890_ElaborateForeach,i8*null)#0
ret void
}
define void@_SML_main540ed99f009ba890_ElaborateForeach()local_unnamed_addr#2 gc"smlsharp"{
%a=load i8,i8*@i,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@i,align 1
tail call void@_SML_main03d87556ec7f64b2_List()#2
tail call void@_SML_main89b8631430c545af_Symbol()#2
tail call void@_SML_maina142c315f12317c0_RecordLabel()#2
br label%d
}
define internal fastcc i8*@_SMLLL3pat_41(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%a to i8**
%d=load i8*,i8**%c,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLLL5idPat_42(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
%e=bitcast i8*%a to i8**
%f=load i8*,i8**%e,align 8
store i8*%f,i8**%c,align 8
%g=call i8*@sml_alloc(i32 inreg 20)#0
%h=getelementptr inbounds i8,i8*%g,i64 -4
%i=bitcast i8*%h to i32*
store i32 1342177296,i32*%i,align 4
store i8*%g,i8**%d,align 8
%j=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%k=bitcast i8*%g to i8**
store i8*%j,i8**%k,align 8
%l=getelementptr inbounds i8,i8*%g,i64 8
%m=bitcast i8*%l to i8**
store i8*null,i8**%m,align 8
%n=getelementptr inbounds i8,i8*%g,i64 16
%o=bitcast i8*%n to i32*
store i32 3,i32*%o,align 4
%p=call i8*@sml_alloc(i32 inreg 20)#0
%q=bitcast i8*%p to i32*
%r=getelementptr inbounds i8,i8*%p,i64 -4
%s=bitcast i8*%r to i32*
store i32 1342177296,i32*%s,align 4
%t=getelementptr inbounds i8,i8*%p,i64 4
%u=bitcast i8*%t to i32*
store i32 0,i32*%u,align 1
store i32 2,i32*%q,align 4
%v=load i8*,i8**%d,align 8
%w=getelementptr inbounds i8,i8*%p,i64 8
%x=bitcast i8*%w to i8**
store i8*%v,i8**%x,align 8
%y=getelementptr inbounds i8,i8*%p,i64 16
%z=bitcast i8*%y to i32*
store i32 2,i32*%z,align 4
ret i8*%p
}
define internal fastcc i8*@_SMLLL3pat_43(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
%j=load i8*,i8**%d,align 8
%k=bitcast i8**%c to i8***
%l=load i8**,i8***%k,align 8
br label%m
m:
%n=phi i8**[%l,%i],[%h,%g]
%o=phi i8*[%j,%i],[%b,%g]
%p=bitcast i8*%o to i8**
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%d,align 8
%r=getelementptr inbounds i8,i8*%o,i64 8
%s=bitcast i8*%r to i8**
%t=load i8*,i8**%s,align 8
%u=getelementptr inbounds i8,i8*%t,i64 16
%v=bitcast i8*%u to i8*(i8*,i8*)**
%w=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%v,align 8
%x=bitcast i8*%t to i8**
%y=load i8*,i8**%x,align 8
store i8*null,i8**%c,align 8
%z=load i8*,i8**%n,align 8
%A=call fastcc i8*%w(i8*inreg%y,i8*inreg%z)
store i8*%A,i8**%c,align 8
%B=call i8*@sml_alloc(i32 inreg 20)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177296,i32*%D,align 4
%E=load i8*,i8**%d,align 8
%F=bitcast i8*%B to i8**
store i8*%E,i8**%F,align 8
%G=load i8*,i8**%c,align 8
%H=getelementptr inbounds i8,i8*%B,i64 8
%I=bitcast i8*%H to i8**
store i8*%G,i8**%I,align 8
%J=getelementptr inbounds i8,i8*%B,i64 16
%K=bitcast i8*%J to i32*
store i32 3,i32*%K,align 4
ret i8*%B
}
define internal fastcc i8*@_SMLLL3pat_44(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
br i1%h,label%j,label%i
i:
call void@sml_check(i32 inreg%g)
br label%j
j:
%k=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%l=getelementptr inbounds i8,i8*%k,i64 16
%m=bitcast i8*%l to i8*(i8*,i8*)**
%n=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%m,align 8
%o=bitcast i8*%k to i8**
%p=load i8*,i8**%o,align 8
store i8*%p,i8**%e,align 8
%q=call i8*@sml_alloc(i32 inreg 12)#0
%r=getelementptr inbounds i8,i8*%q,i64 -4
%s=bitcast i8*%r to i32*
store i32 1342177288,i32*%s,align 4
store i8*%q,i8**%f,align 8
%t=load i8*,i8**%c,align 8
%u=bitcast i8*%q to i8**
store i8*%t,i8**%u,align 8
%v=getelementptr inbounds i8,i8*%q,i64 8
%w=bitcast i8*%v to i32*
store i32 1,i32*%w,align 4
%x=call i8*@sml_alloc(i32 inreg 28)#0
%y=getelementptr inbounds i8,i8*%x,i64 -4
%z=bitcast i8*%y to i32*
store i32 1342177304,i32*%z,align 4
%A=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%B=bitcast i8*%x to i8**
store i8*%A,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%x,i64 8
%D=bitcast i8*%C to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3pat_43 to void(...)*),void(...)**%D,align 8
%E=getelementptr inbounds i8,i8*%x,i64 16
%F=bitcast i8*%E to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3pat_43 to void(...)*),void(...)**%F,align 8
%G=getelementptr inbounds i8,i8*%x,i64 24
%H=bitcast i8*%G to i32*
store i32 -2147483647,i32*%H,align 4
%I=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%J=call fastcc i8*%n(i8*inreg%I,i8*inreg%x)
%K=getelementptr inbounds i8,i8*%J,i64 16
%L=bitcast i8*%K to i8*(i8*,i8*)**
%M=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%L,align 8
%N=bitcast i8*%J to i8**
%O=load i8*,i8**%N,align 8
%P=bitcast i8**%d to i8***
%Q=load i8**,i8***%P,align 8
store i8*null,i8**%d,align 8
%R=load i8*,i8**%Q,align 8
%S=call fastcc i8*%M(i8*inreg%O,i8*inreg%R)
store i8*%S,i8**%d,align 8
%T=call i8*@sml_alloc(i32 inreg 28)#0
%U=getelementptr inbounds i8,i8*%T,i64 -4
%V=bitcast i8*%U to i32*
store i32 1342177304,i32*%V,align 4
store i8*%T,i8**%e,align 8
%W=bitcast i8*%T to i64*
store i64 0,i64*%W,align 4
%X=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%Y=getelementptr inbounds i8,i8*%T,i64 8
%Z=bitcast i8*%Y to i8**
store i8*%X,i8**%Z,align 8
%aa=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ab=getelementptr inbounds i8,i8*%T,i64 16
%ac=bitcast i8*%ab to i8**
store i8*%aa,i8**%ac,align 8
%ad=getelementptr inbounds i8,i8*%T,i64 24
%ae=bitcast i8*%ad to i32*
store i32 6,i32*%ae,align 4
%af=call i8*@sml_alloc(i32 inreg 20)#0
%ag=bitcast i8*%af to i32*
%ah=getelementptr inbounds i8,i8*%af,i64 -4
%ai=bitcast i8*%ah to i32*
store i32 1342177296,i32*%ai,align 4
%aj=getelementptr inbounds i8,i8*%af,i64 4
%ak=bitcast i8*%aj to i32*
store i32 0,i32*%ak,align 1
store i32 4,i32*%ag,align 4
%al=load i8*,i8**%e,align 8
%am=getelementptr inbounds i8,i8*%af,i64 8
%an=bitcast i8*%am to i8**
store i8*%al,i8**%an,align 8
%ao=getelementptr inbounds i8,i8*%af,i64 16
%ap=bitcast i8*%ao to i32*
store i32 2,i32*%ap,align 4
ret i8*%af
}
define internal fastcc i8*@_SMLLLN16ElaborateForeach12elaborateExpE_45(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%a to i8**
%d=load i8*,i8**%c,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLLLN16ElaborateForeach12elaborateExpE_46(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%a to i8**
%d=load i8*,i8**%c,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLLLN16ElaborateForeach12elaborateExpE_47(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
%j=load i8*,i8**%d,align 8
%k=bitcast i8**%c to i8***
%l=load i8**,i8***%k,align 8
br label%m
m:
%n=phi i8**[%l,%i],[%h,%g]
%o=phi i8*[%j,%i],[%b,%g]
%p=bitcast i8*%o to i8**
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%d,align 8
%r=getelementptr inbounds i8,i8*%o,i64 8
%s=bitcast i8*%r to i8**
%t=load i8*,i8**%s,align 8
%u=getelementptr inbounds i8,i8*%t,i64 16
%v=bitcast i8*%u to i8*(i8*,i8*)**
%w=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%v,align 8
%x=bitcast i8*%t to i8**
%y=load i8*,i8**%x,align 8
store i8*null,i8**%c,align 8
%z=load i8*,i8**%n,align 8
%A=call fastcc i8*%w(i8*inreg%y,i8*inreg%z)
store i8*%A,i8**%c,align 8
%B=call i8*@sml_alloc(i32 inreg 20)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177296,i32*%D,align 4
%E=load i8*,i8**%d,align 8
%F=bitcast i8*%B to i8**
store i8*%E,i8**%F,align 8
%G=load i8*,i8**%c,align 8
%H=getelementptr inbounds i8,i8*%B,i64 8
%I=bitcast i8*%H to i8**
store i8*%G,i8**%I,align 8
%J=getelementptr inbounds i8,i8*%B,i64 16
%K=bitcast i8*%J to i32*
store i32 3,i32*%K,align 4
ret i8*%B
}
define internal fastcc i8*@_SMLLLN16ElaborateForeach12elaborateExpE_48(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
%l=call fastcc i8*@_SMLFN6Symbol12mkLongsymbolE(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@c,i64 0,i32 2)to i8*))
%m=getelementptr inbounds i8,i8*%l,i64 16
%n=bitcast i8*%m to i8*(i8*,i8*)**
%o=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%n,align 8
%p=bitcast i8*%l to i8**
%q=load i8*,i8**%p,align 8
%r=load i8*,i8**%c,align 8
%s=call fastcc i8*%o(i8*inreg%q,i8*inreg%r)
store i8*%s,i8**%e,align 8
%t=call i8*@sml_alloc(i32 inreg 20)#0
%u=getelementptr inbounds i8,i8*%t,i64 -4
%v=bitcast i8*%u to i32*
store i32 1342177296,i32*%v,align 4
store i8*%t,i8**%f,align 8
%w=getelementptr inbounds i8,i8*%t,i64 4
%x=bitcast i8*%w to i32*
store i32 0,i32*%x,align 1
%y=bitcast i8*%t to i32*
store i32 25,i32*%y,align 4
%z=load i8*,i8**%e,align 8
%A=getelementptr inbounds i8,i8*%t,i64 8
%B=bitcast i8*%A to i8**
store i8*%z,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%t,i64 16
%D=bitcast i8*%C to i32*
store i32 2,i32*%D,align 4
%E=load i8*,i8**%d,align 8
%F=getelementptr inbounds i8,i8*%E,i64 8
%G=bitcast i8*%F to i8**
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
%O=bitcast i8*%N to i8**
store i8*null,i8**%O,align 8
%P=getelementptr inbounds i8,i8*%I,i64 16
%Q=bitcast i8*%P to i32*
store i32 3,i32*%Q,align 4
%R=call i8*@sml_alloc(i32 inreg 28)#0
%S=getelementptr inbounds i8,i8*%R,i64 -4
%T=bitcast i8*%S to i32*
store i32 1342177304,i32*%T,align 4
store i8*%R,i8**%e,align 8
%U=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%V=bitcast i8*%R to i8**
store i8*%U,i8**%V,align 8
%W=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%X=getelementptr inbounds i8,i8*%R,i64 8
%Y=bitcast i8*%X to i8**
store i8*%W,i8**%Y,align 8
%Z=load i8*,i8**%c,align 8
%aa=getelementptr inbounds i8,i8*%R,i64 16
%ab=bitcast i8*%aa to i8**
store i8*%Z,i8**%ab,align 8
%ac=getelementptr inbounds i8,i8*%R,i64 24
%ad=bitcast i8*%ac to i32*
store i32 7,i32*%ad,align 4
%ae=call i8*@sml_alloc(i32 inreg 20)#0
%af=getelementptr inbounds i8,i8*%ae,i64 -4
%ag=bitcast i8*%af to i32*
store i32 1342177296,i32*%ag,align 4
store i8*%ae,i8**%g,align 8
%ah=bitcast i8*%ae to i64*
store i64 0,i64*%ah,align 4
%ai=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aj=getelementptr inbounds i8,i8*%ae,i64 8
%ak=bitcast i8*%aj to i8**
store i8*%ai,i8**%ak,align 8
%al=getelementptr inbounds i8,i8*%ae,i64 16
%am=bitcast i8*%al to i32*
store i32 2,i32*%am,align 4
%an=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%ao=getelementptr inbounds i8,i8*%an,i64 16
%ap=bitcast i8*%ao to i8*(i8*,i8*)**
%aq=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ap,align 8
%ar=bitcast i8*%an to i8**
%as=load i8*,i8**%ar,align 8
store i8*%as,i8**%e,align 8
%at=call i8*@sml_alloc(i32 inreg 12)#0
%au=getelementptr inbounds i8,i8*%at,i64 -4
%av=bitcast i8*%au to i32*
store i32 1342177288,i32*%av,align 4
store i8*%at,i8**%f,align 8
%aw=load i8*,i8**%c,align 8
%ax=bitcast i8*%at to i8**
store i8*%aw,i8**%ax,align 8
%ay=getelementptr inbounds i8,i8*%at,i64 8
%az=bitcast i8*%ay to i32*
store i32 1,i32*%az,align 4
%aA=call i8*@sml_alloc(i32 inreg 28)#0
%aB=getelementptr inbounds i8,i8*%aA,i64 -4
%aC=bitcast i8*%aB to i32*
store i32 1342177304,i32*%aC,align 4
%aD=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aE=bitcast i8*%aA to i8**
store i8*%aD,i8**%aE,align 8
%aF=getelementptr inbounds i8,i8*%aA,i64 8
%aG=bitcast i8*%aF to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_47 to void(...)*),void(...)**%aG,align 8
%aH=getelementptr inbounds i8,i8*%aA,i64 16
%aI=bitcast i8*%aH to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_47 to void(...)*),void(...)**%aI,align 8
%aJ=getelementptr inbounds i8,i8*%aA,i64 24
%aK=bitcast i8*%aJ to i32*
store i32 -2147483647,i32*%aK,align 4
%aL=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aM=call fastcc i8*%aq(i8*inreg%aL,i8*inreg%aA)
%aN=getelementptr inbounds i8,i8*%aM,i64 16
%aO=bitcast i8*%aN to i8*(i8*,i8*)**
%aP=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aO,align 8
%aQ=bitcast i8*%aM to i8**
%aR=load i8*,i8**%aQ,align 8
%aS=bitcast i8**%d to i8***
%aT=load i8**,i8***%aS,align 8
%aU=load i8*,i8**%aT,align 8
%aV=call fastcc i8*%aP(i8*inreg%aR,i8*inreg%aU)
store i8*%aV,i8**%e,align 8
%aW=call i8*@sml_alloc(i32 inreg 28)#0
%aX=getelementptr inbounds i8,i8*%aW,i64 -4
%aY=bitcast i8*%aX to i32*
store i32 1342177304,i32*%aY,align 4
store i8*%aW,i8**%f,align 8
%aZ=bitcast i8*%aW to i64*
store i64 0,i64*%aZ,align 4
%a0=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%a1=getelementptr inbounds i8,i8*%aW,i64 8
%a2=bitcast i8*%a1 to i8**
store i8*%a0,i8**%a2,align 8
%a3=load i8*,i8**%c,align 8
%a4=getelementptr inbounds i8,i8*%aW,i64 16
%a5=bitcast i8*%a4 to i8**
store i8*%a3,i8**%a5,align 8
%a6=getelementptr inbounds i8,i8*%aW,i64 24
%a7=bitcast i8*%a6 to i32*
store i32 6,i32*%a7,align 4
%a8=call i8*@sml_alloc(i32 inreg 20)#0
%a9=getelementptr inbounds i8,i8*%a8,i64 -4
%ba=bitcast i8*%a9 to i32*
store i32 1342177296,i32*%ba,align 4
store i8*%a8,i8**%e,align 8
%bb=getelementptr inbounds i8,i8*%a8,i64 4
%bc=bitcast i8*%bb to i32*
store i32 0,i32*%bc,align 1
%bd=bitcast i8*%a8 to i32*
store i32 4,i32*%bd,align 4
%be=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bf=getelementptr inbounds i8,i8*%a8,i64 8
%bg=bitcast i8*%bf to i8**
store i8*%be,i8**%bg,align 8
%bh=getelementptr inbounds i8,i8*%a8,i64 16
%bi=bitcast i8*%bh to i32*
store i32 2,i32*%bi,align 4
%bj=call i8*@sml_alloc(i32 inreg 20)#0
%bk=getelementptr inbounds i8,i8*%bj,i64 -4
%bl=bitcast i8*%bk to i32*
store i32 1342177296,i32*%bl,align 4
store i8*%bj,i8**%f,align 8
%bm=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bn=bitcast i8*%bj to i8**
store i8*%bm,i8**%bn,align 8
%bo=getelementptr inbounds i8,i8*%bj,i64 8
%bp=bitcast i8*%bo to i8**
store i8*null,i8**%bp,align 8
%bq=getelementptr inbounds i8,i8*%bj,i64 16
%br=bitcast i8*%bq to i32*
store i32 3,i32*%br,align 4
%bs=load i8*,i8**%d,align 8
%bt=getelementptr inbounds i8,i8*%bs,i64 16
%bu=bitcast i8*%bt to i8**
%bv=load i8*,i8**%bu,align 8
store i8*%bv,i8**%d,align 8
%bw=call i8*@sml_alloc(i32 inreg 28)#0
%bx=getelementptr inbounds i8,i8*%bw,i64 -4
%by=bitcast i8*%bx to i32*
store i32 1342177304,i32*%by,align 4
store i8*%bw,i8**%e,align 8
%bz=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bA=bitcast i8*%bw to i8**
store i8*%bz,i8**%bA,align 8
%bB=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bC=getelementptr inbounds i8,i8*%bw,i64 8
%bD=bitcast i8*%bC to i8**
store i8*%bB,i8**%bD,align 8
%bE=load i8*,i8**%c,align 8
%bF=getelementptr inbounds i8,i8*%bw,i64 16
%bG=bitcast i8*%bF to i8**
store i8*%bE,i8**%bG,align 8
%bH=getelementptr inbounds i8,i8*%bw,i64 24
%bI=bitcast i8*%bH to i32*
store i32 7,i32*%bI,align 4
%bJ=call i8*@sml_alloc(i32 inreg 20)#0
%bK=getelementptr inbounds i8,i8*%bJ,i64 -4
%bL=bitcast i8*%bK to i32*
store i32 1342177296,i32*%bL,align 4
store i8*%bJ,i8**%f,align 8
%bM=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bN=bitcast i8*%bJ to i8**
store i8*%bM,i8**%bN,align 8
%bO=getelementptr inbounds i8,i8*%bJ,i64 8
%bP=bitcast i8*%bO to i8**
store i8*null,i8**%bP,align 8
%bQ=getelementptr inbounds i8,i8*%bJ,i64 16
%bR=bitcast i8*%bQ to i32*
store i32 3,i32*%bR,align 4
%bS=call i8*@sml_alloc(i32 inreg 20)#0
%bT=getelementptr inbounds i8,i8*%bS,i64 -4
%bU=bitcast i8*%bT to i32*
store i32 1342177296,i32*%bU,align 4
store i8*%bS,i8**%d,align 8
%bV=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bW=bitcast i8*%bS to i8**
store i8*%bV,i8**%bW,align 8
%bX=load i8*,i8**%c,align 8
%bY=getelementptr inbounds i8,i8*%bS,i64 8
%bZ=bitcast i8*%bY to i8**
store i8*%bX,i8**%bZ,align 8
%b0=getelementptr inbounds i8,i8*%bS,i64 16
%b1=bitcast i8*%b0 to i32*
store i32 3,i32*%b1,align 4
%b2=call i8*@sml_alloc(i32 inreg 20)#0
%b3=getelementptr inbounds i8,i8*%b2,i64 -4
%b4=bitcast i8*%b3 to i32*
store i32 1342177296,i32*%b4,align 4
store i8*%b2,i8**%e,align 8
%b5=getelementptr inbounds i8,i8*%b2,i64 4
%b6=bitcast i8*%b5 to i32*
store i32 0,i32*%b6,align 1
%b7=bitcast i8*%b2 to i32*
store i32 10,i32*%b7,align 4
%b8=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%b9=getelementptr inbounds i8,i8*%b2,i64 8
%ca=bitcast i8*%b9 to i8**
store i8*%b8,i8**%ca,align 8
%cb=getelementptr inbounds i8,i8*%b2,i64 16
%cc=bitcast i8*%cb to i32*
store i32 2,i32*%cc,align 4
%cd=call i8*@sml_alloc(i32 inreg 20)#0
%ce=getelementptr inbounds i8,i8*%cd,i64 -4
%cf=bitcast i8*%ce to i32*
store i32 1342177296,i32*%cf,align 4
store i8*%cd,i8**%f,align 8
%cg=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ch=bitcast i8*%cd to i8**
store i8*%cg,i8**%ch,align 8
%ci=getelementptr inbounds i8,i8*%cd,i64 8
%cj=bitcast i8*%ci to i8**
store i8*null,i8**%cj,align 8
%ck=getelementptr inbounds i8,i8*%cd,i64 16
%cl=bitcast i8*%ck to i32*
store i32 3,i32*%cl,align 4
%cm=call i8*@sml_alloc(i32 inreg 28)#0
%cn=getelementptr inbounds i8,i8*%cm,i64 -4
%co=bitcast i8*%cn to i32*
store i32 1342177304,i32*%co,align 4
store i8*%cm,i8**%d,align 8
%cp=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%cq=bitcast i8*%cm to i8**
store i8*%cp,i8**%cq,align 8
%cr=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%cs=getelementptr inbounds i8,i8*%cm,i64 8
%ct=bitcast i8*%cs to i8**
store i8*%cr,i8**%ct,align 8
%cu=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%cv=getelementptr inbounds i8,i8*%cm,i64 16
%cw=bitcast i8*%cv to i8**
store i8*%cu,i8**%cw,align 8
%cx=getelementptr inbounds i8,i8*%cm,i64 24
%cy=bitcast i8*%cx to i32*
store i32 7,i32*%cy,align 4
%cz=call i8*@sml_alloc(i32 inreg 20)#0
%cA=getelementptr inbounds i8,i8*%cz,i64 -4
%cB=bitcast i8*%cA to i32*
store i32 1342177296,i32*%cB,align 4
%cC=bitcast i8*%cz to i64*
store i64 0,i64*%cC,align 4
%cD=load i8*,i8**%d,align 8
%cE=getelementptr inbounds i8,i8*%cz,i64 8
%cF=bitcast i8*%cE to i8**
store i8*%cD,i8**%cF,align 8
%cG=getelementptr inbounds i8,i8*%cz,i64 16
%cH=bitcast i8*%cG to i32*
store i32 2,i32*%cH,align 4
ret i8*%cz
}
define internal fastcc i8*@_SMLLLN16ElaborateForeach12elaborateExpE_49(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
%j=load i8*,i8**%d,align 8
%k=bitcast i8**%c to i8***
%l=load i8**,i8***%k,align 8
br label%m
m:
%n=phi i8**[%l,%i],[%h,%g]
%o=phi i8*[%j,%i],[%b,%g]
%p=bitcast i8*%o to i8**
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%d,align 8
%r=getelementptr inbounds i8,i8*%o,i64 8
%s=bitcast i8*%r to i8**
%t=load i8*,i8**%s,align 8
%u=getelementptr inbounds i8,i8*%t,i64 16
%v=bitcast i8*%u to i8*(i8*,i8*)**
%w=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%v,align 8
%x=bitcast i8*%t to i8**
%y=load i8*,i8**%x,align 8
store i8*null,i8**%c,align 8
%z=load i8*,i8**%n,align 8
%A=call fastcc i8*%w(i8*inreg%y,i8*inreg%z)
store i8*%A,i8**%c,align 8
%B=call i8*@sml_alloc(i32 inreg 20)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177296,i32*%D,align 4
%E=load i8*,i8**%d,align 8
%F=bitcast i8*%B to i8**
store i8*%E,i8**%F,align 8
%G=load i8*,i8**%c,align 8
%H=getelementptr inbounds i8,i8*%B,i64 8
%I=bitcast i8*%H to i8**
store i8*%G,i8**%I,align 8
%J=getelementptr inbounds i8,i8*%B,i64 16
%K=bitcast i8*%J to i32*
store i32 3,i32*%K,align 4
ret i8*%B
}
define internal fastcc i8*@_SMLLL3pat_50(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%a to i8**
%d=load i8*,i8**%c,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLLL5idPat_51(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
%e=bitcast i8*%a to i8**
%f=load i8*,i8**%e,align 8
store i8*%f,i8**%c,align 8
%g=call i8*@sml_alloc(i32 inreg 20)#0
%h=getelementptr inbounds i8,i8*%g,i64 -4
%i=bitcast i8*%h to i32*
store i32 1342177296,i32*%i,align 4
store i8*%g,i8**%d,align 8
%j=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%k=bitcast i8*%g to i8**
store i8*%j,i8**%k,align 8
%l=getelementptr inbounds i8,i8*%g,i64 8
%m=bitcast i8*%l to i8**
store i8*null,i8**%m,align 8
%n=getelementptr inbounds i8,i8*%g,i64 16
%o=bitcast i8*%n to i32*
store i32 3,i32*%o,align 4
%p=call i8*@sml_alloc(i32 inreg 20)#0
%q=bitcast i8*%p to i32*
%r=getelementptr inbounds i8,i8*%p,i64 -4
%s=bitcast i8*%r to i32*
store i32 1342177296,i32*%s,align 4
%t=getelementptr inbounds i8,i8*%p,i64 4
%u=bitcast i8*%t to i32*
store i32 0,i32*%u,align 1
store i32 2,i32*%q,align 4
%v=load i8*,i8**%d,align 8
%w=getelementptr inbounds i8,i8*%p,i64 8
%x=bitcast i8*%w to i8**
store i8*%v,i8**%x,align 8
%y=getelementptr inbounds i8,i8*%p,i64 16
%z=bitcast i8*%y to i32*
store i32 2,i32*%z,align 4
ret i8*%p
}
define internal fastcc i8*@_SMLLL3pat_52(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
%j=load i8*,i8**%d,align 8
%k=bitcast i8**%c to i8***
%l=load i8**,i8***%k,align 8
br label%m
m:
%n=phi i8**[%l,%i],[%h,%g]
%o=phi i8*[%j,%i],[%b,%g]
%p=bitcast i8*%o to i8**
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%d,align 8
%r=getelementptr inbounds i8,i8*%o,i64 8
%s=bitcast i8*%r to i8**
%t=load i8*,i8**%s,align 8
%u=getelementptr inbounds i8,i8*%t,i64 16
%v=bitcast i8*%u to i8*(i8*,i8*)**
%w=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%v,align 8
%x=bitcast i8*%t to i8**
%y=load i8*,i8**%x,align 8
store i8*null,i8**%c,align 8
%z=load i8*,i8**%n,align 8
%A=call fastcc i8*%w(i8*inreg%y,i8*inreg%z)
store i8*%A,i8**%c,align 8
%B=call i8*@sml_alloc(i32 inreg 20)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177296,i32*%D,align 4
%E=load i8*,i8**%d,align 8
%F=bitcast i8*%B to i8**
store i8*%E,i8**%F,align 8
%G=load i8*,i8**%c,align 8
%H=getelementptr inbounds i8,i8*%B,i64 8
%I=bitcast i8*%H to i8**
store i8*%G,i8**%I,align 8
%J=getelementptr inbounds i8,i8*%B,i64 16
%K=bitcast i8*%J to i32*
store i32 3,i32*%K,align 4
ret i8*%B
}
define internal fastcc i8*@_SMLLL3pat_53(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
br i1%h,label%j,label%i
i:
call void@sml_check(i32 inreg%g)
br label%j
j:
%k=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%l=getelementptr inbounds i8,i8*%k,i64 16
%m=bitcast i8*%l to i8*(i8*,i8*)**
%n=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%m,align 8
%o=bitcast i8*%k to i8**
%p=load i8*,i8**%o,align 8
store i8*%p,i8**%e,align 8
%q=call i8*@sml_alloc(i32 inreg 12)#0
%r=getelementptr inbounds i8,i8*%q,i64 -4
%s=bitcast i8*%r to i32*
store i32 1342177288,i32*%s,align 4
store i8*%q,i8**%f,align 8
%t=load i8*,i8**%c,align 8
%u=bitcast i8*%q to i8**
store i8*%t,i8**%u,align 8
%v=getelementptr inbounds i8,i8*%q,i64 8
%w=bitcast i8*%v to i32*
store i32 1,i32*%w,align 4
%x=call i8*@sml_alloc(i32 inreg 28)#0
%y=getelementptr inbounds i8,i8*%x,i64 -4
%z=bitcast i8*%y to i32*
store i32 1342177304,i32*%z,align 4
%A=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%B=bitcast i8*%x to i8**
store i8*%A,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%x,i64 8
%D=bitcast i8*%C to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3pat_52 to void(...)*),void(...)**%D,align 8
%E=getelementptr inbounds i8,i8*%x,i64 16
%F=bitcast i8*%E to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3pat_52 to void(...)*),void(...)**%F,align 8
%G=getelementptr inbounds i8,i8*%x,i64 24
%H=bitcast i8*%G to i32*
store i32 -2147483647,i32*%H,align 4
%I=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%J=call fastcc i8*%n(i8*inreg%I,i8*inreg%x)
%K=getelementptr inbounds i8,i8*%J,i64 16
%L=bitcast i8*%K to i8*(i8*,i8*)**
%M=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%L,align 8
%N=bitcast i8*%J to i8**
%O=load i8*,i8**%N,align 8
%P=bitcast i8**%d to i8***
%Q=load i8**,i8***%P,align 8
store i8*null,i8**%d,align 8
%R=load i8*,i8**%Q,align 8
%S=call fastcc i8*%M(i8*inreg%O,i8*inreg%R)
store i8*%S,i8**%d,align 8
%T=call i8*@sml_alloc(i32 inreg 28)#0
%U=getelementptr inbounds i8,i8*%T,i64 -4
%V=bitcast i8*%U to i32*
store i32 1342177304,i32*%V,align 4
store i8*%T,i8**%e,align 8
%W=bitcast i8*%T to i64*
store i64 0,i64*%W,align 4
%X=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%Y=getelementptr inbounds i8,i8*%T,i64 8
%Z=bitcast i8*%Y to i8**
store i8*%X,i8**%Z,align 8
%aa=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ab=getelementptr inbounds i8,i8*%T,i64 16
%ac=bitcast i8*%ab to i8**
store i8*%aa,i8**%ac,align 8
%ad=getelementptr inbounds i8,i8*%T,i64 24
%ae=bitcast i8*%ad to i32*
store i32 6,i32*%ae,align 4
%af=call i8*@sml_alloc(i32 inreg 20)#0
%ag=bitcast i8*%af to i32*
%ah=getelementptr inbounds i8,i8*%af,i64 -4
%ai=bitcast i8*%ah to i32*
store i32 1342177296,i32*%ai,align 4
%aj=getelementptr inbounds i8,i8*%af,i64 4
%ak=bitcast i8*%aj to i32*
store i32 0,i32*%ak,align 1
store i32 4,i32*%ag,align 4
%al=load i8*,i8**%e,align 8
%am=getelementptr inbounds i8,i8*%af,i64 8
%an=bitcast i8*%am to i8**
store i8*%al,i8**%an,align 8
%ao=getelementptr inbounds i8,i8*%af,i64 16
%ap=bitcast i8*%ao to i32*
store i32 2,i32*%ap,align 4
ret i8*%af
}
define internal fastcc i8*@_SMLLLN16ElaborateForeach12elaborateExpE_54(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%a to i8**
%d=load i8*,i8**%c,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLLLN16ElaborateForeach12elaborateExpE_55(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%a to i8**
%d=load i8*,i8**%c,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLLLN16ElaborateForeach12elaborateExpE_56(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
%j=load i8*,i8**%d,align 8
%k=bitcast i8**%c to i8***
%l=load i8**,i8***%k,align 8
br label%m
m:
%n=phi i8**[%l,%i],[%h,%g]
%o=phi i8*[%j,%i],[%b,%g]
%p=bitcast i8*%o to i8**
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%d,align 8
%r=getelementptr inbounds i8,i8*%o,i64 8
%s=bitcast i8*%r to i8**
%t=load i8*,i8**%s,align 8
%u=getelementptr inbounds i8,i8*%t,i64 16
%v=bitcast i8*%u to i8*(i8*,i8*)**
%w=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%v,align 8
%x=bitcast i8*%t to i8**
%y=load i8*,i8**%x,align 8
store i8*null,i8**%c,align 8
%z=load i8*,i8**%n,align 8
%A=call fastcc i8*%w(i8*inreg%y,i8*inreg%z)
store i8*%A,i8**%c,align 8
%B=call i8*@sml_alloc(i32 inreg 20)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177296,i32*%D,align 4
%E=load i8*,i8**%d,align 8
%F=bitcast i8*%B to i8**
store i8*%E,i8**%F,align 8
%G=load i8*,i8**%c,align 8
%H=getelementptr inbounds i8,i8*%B,i64 8
%I=bitcast i8*%H to i8**
store i8*%G,i8**%I,align 8
%J=getelementptr inbounds i8,i8*%B,i64 16
%K=bitcast i8*%J to i32*
store i32 3,i32*%K,align 4
ret i8*%B
}
define internal fastcc i8*@_SMLLLN16ElaborateForeach12elaborateExpE_57(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
%l=call fastcc i8*@_SMLFN6Symbol12mkLongsymbolE(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@f,i64 0,i32 2)to i8*))
%m=getelementptr inbounds i8,i8*%l,i64 16
%n=bitcast i8*%m to i8*(i8*,i8*)**
%o=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%n,align 8
%p=bitcast i8*%l to i8**
%q=load i8*,i8**%p,align 8
%r=load i8*,i8**%c,align 8
%s=call fastcc i8*%o(i8*inreg%q,i8*inreg%r)
store i8*%s,i8**%e,align 8
%t=call i8*@sml_alloc(i32 inreg 20)#0
%u=getelementptr inbounds i8,i8*%t,i64 -4
%v=bitcast i8*%u to i32*
store i32 1342177296,i32*%v,align 4
store i8*%t,i8**%f,align 8
%w=getelementptr inbounds i8,i8*%t,i64 4
%x=bitcast i8*%w to i32*
store i32 0,i32*%x,align 1
%y=bitcast i8*%t to i32*
store i32 25,i32*%y,align 4
%z=load i8*,i8**%e,align 8
%A=getelementptr inbounds i8,i8*%t,i64 8
%B=bitcast i8*%A to i8**
store i8*%z,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%t,i64 16
%D=bitcast i8*%C to i32*
store i32 2,i32*%D,align 4
%E=load i8*,i8**%d,align 8
%F=getelementptr inbounds i8,i8*%E,i64 16
%G=bitcast i8*%F to i8**
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
%O=bitcast i8*%N to i8**
store i8*null,i8**%O,align 8
%P=getelementptr inbounds i8,i8*%I,i64 16
%Q=bitcast i8*%P to i32*
store i32 3,i32*%Q,align 4
%R=call i8*@sml_alloc(i32 inreg 28)#0
%S=getelementptr inbounds i8,i8*%R,i64 -4
%T=bitcast i8*%S to i32*
store i32 1342177304,i32*%T,align 4
store i8*%R,i8**%e,align 8
%U=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%V=bitcast i8*%R to i8**
store i8*%U,i8**%V,align 8
%W=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%X=getelementptr inbounds i8,i8*%R,i64 8
%Y=bitcast i8*%X to i8**
store i8*%W,i8**%Y,align 8
%Z=load i8*,i8**%c,align 8
%aa=getelementptr inbounds i8,i8*%R,i64 16
%ab=bitcast i8*%aa to i8**
store i8*%Z,i8**%ab,align 8
%ac=getelementptr inbounds i8,i8*%R,i64 24
%ad=bitcast i8*%ac to i32*
store i32 7,i32*%ad,align 4
%ae=call i8*@sml_alloc(i32 inreg 20)#0
%af=getelementptr inbounds i8,i8*%ae,i64 -4
%ag=bitcast i8*%af to i32*
store i32 1342177296,i32*%ag,align 4
store i8*%ae,i8**%f,align 8
%ah=bitcast i8*%ae to i64*
store i64 0,i64*%ah,align 4
%ai=load i8*,i8**%e,align 8
%aj=getelementptr inbounds i8,i8*%ae,i64 8
%ak=bitcast i8*%aj to i8**
store i8*%ai,i8**%ak,align 8
%al=getelementptr inbounds i8,i8*%ae,i64 16
%am=bitcast i8*%al to i32*
store i32 2,i32*%am,align 4
%an=load i8*,i8**%d,align 8
%ao=getelementptr inbounds i8,i8*%an,i64 8
%ap=bitcast i8*%ao to i8**
%aq=load i8*,i8**%ap,align 8
store i8*%aq,i8**%e,align 8
%ar=call i8*@sml_alloc(i32 inreg 20)#0
%as=getelementptr inbounds i8,i8*%ar,i64 -4
%at=bitcast i8*%as to i32*
store i32 1342177296,i32*%at,align 4
store i8*%ar,i8**%g,align 8
%au=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%av=bitcast i8*%ar to i8**
store i8*%au,i8**%av,align 8
%aw=getelementptr inbounds i8,i8*%ar,i64 8
%ax=bitcast i8*%aw to i8**
store i8*null,i8**%ax,align 8
%ay=getelementptr inbounds i8,i8*%ar,i64 16
%az=bitcast i8*%ay to i32*
store i32 3,i32*%az,align 4
%aA=call i8*@sml_alloc(i32 inreg 28)#0
%aB=getelementptr inbounds i8,i8*%aA,i64 -4
%aC=bitcast i8*%aB to i32*
store i32 1342177304,i32*%aC,align 4
store i8*%aA,i8**%e,align 8
%aD=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aE=bitcast i8*%aA to i8**
store i8*%aD,i8**%aE,align 8
%aF=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aG=getelementptr inbounds i8,i8*%aA,i64 8
%aH=bitcast i8*%aG to i8**
store i8*%aF,i8**%aH,align 8
%aI=load i8*,i8**%c,align 8
%aJ=getelementptr inbounds i8,i8*%aA,i64 16
%aK=bitcast i8*%aJ to i8**
store i8*%aI,i8**%aK,align 8
%aL=getelementptr inbounds i8,i8*%aA,i64 24
%aM=bitcast i8*%aL to i32*
store i32 7,i32*%aM,align 4
%aN=call i8*@sml_alloc(i32 inreg 20)#0
%aO=getelementptr inbounds i8,i8*%aN,i64 -4
%aP=bitcast i8*%aO to i32*
store i32 1342177296,i32*%aP,align 4
store i8*%aN,i8**%g,align 8
%aQ=bitcast i8*%aN to i64*
store i64 0,i64*%aQ,align 4
%aR=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aS=getelementptr inbounds i8,i8*%aN,i64 8
%aT=bitcast i8*%aS to i8**
store i8*%aR,i8**%aT,align 8
%aU=getelementptr inbounds i8,i8*%aN,i64 16
%aV=bitcast i8*%aU to i32*
store i32 2,i32*%aV,align 4
%aW=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%aX=getelementptr inbounds i8,i8*%aW,i64 16
%aY=bitcast i8*%aX to i8*(i8*,i8*)**
%aZ=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aY,align 8
%a0=bitcast i8*%aW to i8**
%a1=load i8*,i8**%a0,align 8
store i8*%a1,i8**%e,align 8
%a2=call i8*@sml_alloc(i32 inreg 12)#0
%a3=getelementptr inbounds i8,i8*%a2,i64 -4
%a4=bitcast i8*%a3 to i32*
store i32 1342177288,i32*%a4,align 4
store i8*%a2,i8**%f,align 8
%a5=load i8*,i8**%c,align 8
%a6=bitcast i8*%a2 to i8**
store i8*%a5,i8**%a6,align 8
%a7=getelementptr inbounds i8,i8*%a2,i64 8
%a8=bitcast i8*%a7 to i32*
store i32 1,i32*%a8,align 4
%a9=call i8*@sml_alloc(i32 inreg 28)#0
%ba=getelementptr inbounds i8,i8*%a9,i64 -4
%bb=bitcast i8*%ba to i32*
store i32 1342177304,i32*%bb,align 4
%bc=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bd=bitcast i8*%a9 to i8**
store i8*%bc,i8**%bd,align 8
%be=getelementptr inbounds i8,i8*%a9,i64 8
%bf=bitcast i8*%be to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_56 to void(...)*),void(...)**%bf,align 8
%bg=getelementptr inbounds i8,i8*%a9,i64 16
%bh=bitcast i8*%bg to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_56 to void(...)*),void(...)**%bh,align 8
%bi=getelementptr inbounds i8,i8*%a9,i64 24
%bj=bitcast i8*%bi to i32*
store i32 -2147483647,i32*%bj,align 4
%bk=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bl=call fastcc i8*%aZ(i8*inreg%bk,i8*inreg%a9)
%bm=getelementptr inbounds i8,i8*%bl,i64 16
%bn=bitcast i8*%bm to i8*(i8*,i8*)**
%bo=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bn,align 8
%bp=bitcast i8*%bl to i8**
%bq=load i8*,i8**%bp,align 8
%br=bitcast i8**%d to i8***
%bs=load i8**,i8***%br,align 8
%bt=load i8*,i8**%bs,align 8
%bu=call fastcc i8*%bo(i8*inreg%bq,i8*inreg%bt)
store i8*%bu,i8**%e,align 8
%bv=call i8*@sml_alloc(i32 inreg 28)#0
%bw=getelementptr inbounds i8,i8*%bv,i64 -4
%bx=bitcast i8*%bw to i32*
store i32 1342177304,i32*%bx,align 4
store i8*%bv,i8**%f,align 8
%by=bitcast i8*%bv to i64*
store i64 0,i64*%by,align 4
%bz=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bA=getelementptr inbounds i8,i8*%bv,i64 8
%bB=bitcast i8*%bA to i8**
store i8*%bz,i8**%bB,align 8
%bC=load i8*,i8**%c,align 8
%bD=getelementptr inbounds i8,i8*%bv,i64 16
%bE=bitcast i8*%bD to i8**
store i8*%bC,i8**%bE,align 8
%bF=getelementptr inbounds i8,i8*%bv,i64 24
%bG=bitcast i8*%bF to i32*
store i32 6,i32*%bG,align 4
%bH=call i8*@sml_alloc(i32 inreg 20)#0
%bI=getelementptr inbounds i8,i8*%bH,i64 -4
%bJ=bitcast i8*%bI to i32*
store i32 1342177296,i32*%bJ,align 4
store i8*%bH,i8**%e,align 8
%bK=getelementptr inbounds i8,i8*%bH,i64 4
%bL=bitcast i8*%bK to i32*
store i32 0,i32*%bL,align 1
%bM=bitcast i8*%bH to i32*
store i32 4,i32*%bM,align 4
%bN=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bO=getelementptr inbounds i8,i8*%bH,i64 8
%bP=bitcast i8*%bO to i8**
store i8*%bN,i8**%bP,align 8
%bQ=getelementptr inbounds i8,i8*%bH,i64 16
%bR=bitcast i8*%bQ to i32*
store i32 2,i32*%bR,align 4
%bS=call i8*@sml_alloc(i32 inreg 20)#0
%bT=getelementptr inbounds i8,i8*%bS,i64 -4
%bU=bitcast i8*%bT to i32*
store i32 1342177296,i32*%bU,align 4
store i8*%bS,i8**%f,align 8
%bV=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bW=bitcast i8*%bS to i8**
store i8*%bV,i8**%bW,align 8
%bX=getelementptr inbounds i8,i8*%bS,i64 8
%bY=bitcast i8*%bX to i8**
store i8*null,i8**%bY,align 8
%bZ=getelementptr inbounds i8,i8*%bS,i64 16
%b0=bitcast i8*%bZ to i32*
store i32 3,i32*%b0,align 4
%b1=load i8*,i8**%d,align 8
%b2=getelementptr inbounds i8,i8*%b1,i64 24
%b3=bitcast i8*%b2 to i8**
%b4=load i8*,i8**%b3,align 8
store i8*%b4,i8**%d,align 8
%b5=call i8*@sml_alloc(i32 inreg 28)#0
%b6=getelementptr inbounds i8,i8*%b5,i64 -4
%b7=bitcast i8*%b6 to i32*
store i32 1342177304,i32*%b7,align 4
store i8*%b5,i8**%e,align 8
%b8=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%b9=bitcast i8*%b5 to i8**
store i8*%b8,i8**%b9,align 8
%ca=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%cb=getelementptr inbounds i8,i8*%b5,i64 8
%cc=bitcast i8*%cb to i8**
store i8*%ca,i8**%cc,align 8
%cd=load i8*,i8**%c,align 8
%ce=getelementptr inbounds i8,i8*%b5,i64 16
%cf=bitcast i8*%ce to i8**
store i8*%cd,i8**%cf,align 8
%cg=getelementptr inbounds i8,i8*%b5,i64 24
%ch=bitcast i8*%cg to i32*
store i32 7,i32*%ch,align 4
%ci=call i8*@sml_alloc(i32 inreg 20)#0
%cj=getelementptr inbounds i8,i8*%ci,i64 -4
%ck=bitcast i8*%cj to i32*
store i32 1342177296,i32*%ck,align 4
store i8*%ci,i8**%f,align 8
%cl=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%cm=bitcast i8*%ci to i8**
store i8*%cl,i8**%cm,align 8
%cn=getelementptr inbounds i8,i8*%ci,i64 8
%co=bitcast i8*%cn to i8**
store i8*null,i8**%co,align 8
%cp=getelementptr inbounds i8,i8*%ci,i64 16
%cq=bitcast i8*%cp to i32*
store i32 3,i32*%cq,align 4
%cr=call i8*@sml_alloc(i32 inreg 20)#0
%cs=getelementptr inbounds i8,i8*%cr,i64 -4
%ct=bitcast i8*%cs to i32*
store i32 1342177296,i32*%ct,align 4
store i8*%cr,i8**%d,align 8
%cu=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%cv=bitcast i8*%cr to i8**
store i8*%cu,i8**%cv,align 8
%cw=load i8*,i8**%c,align 8
%cx=getelementptr inbounds i8,i8*%cr,i64 8
%cy=bitcast i8*%cx to i8**
store i8*%cw,i8**%cy,align 8
%cz=getelementptr inbounds i8,i8*%cr,i64 16
%cA=bitcast i8*%cz to i32*
store i32 3,i32*%cA,align 4
%cB=call i8*@sml_alloc(i32 inreg 20)#0
%cC=getelementptr inbounds i8,i8*%cB,i64 -4
%cD=bitcast i8*%cC to i32*
store i32 1342177296,i32*%cD,align 4
store i8*%cB,i8**%e,align 8
%cE=getelementptr inbounds i8,i8*%cB,i64 4
%cF=bitcast i8*%cE to i32*
store i32 0,i32*%cF,align 1
%cG=bitcast i8*%cB to i32*
store i32 10,i32*%cG,align 4
%cH=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%cI=getelementptr inbounds i8,i8*%cB,i64 8
%cJ=bitcast i8*%cI to i8**
store i8*%cH,i8**%cJ,align 8
%cK=getelementptr inbounds i8,i8*%cB,i64 16
%cL=bitcast i8*%cK to i32*
store i32 2,i32*%cL,align 4
%cM=call i8*@sml_alloc(i32 inreg 20)#0
%cN=getelementptr inbounds i8,i8*%cM,i64 -4
%cO=bitcast i8*%cN to i32*
store i32 1342177296,i32*%cO,align 4
store i8*%cM,i8**%f,align 8
%cP=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%cQ=bitcast i8*%cM to i8**
store i8*%cP,i8**%cQ,align 8
%cR=getelementptr inbounds i8,i8*%cM,i64 8
%cS=bitcast i8*%cR to i8**
store i8*null,i8**%cS,align 8
%cT=getelementptr inbounds i8,i8*%cM,i64 16
%cU=bitcast i8*%cT to i32*
store i32 3,i32*%cU,align 4
%cV=call i8*@sml_alloc(i32 inreg 28)#0
%cW=getelementptr inbounds i8,i8*%cV,i64 -4
%cX=bitcast i8*%cW to i32*
store i32 1342177304,i32*%cX,align 4
store i8*%cV,i8**%d,align 8
%cY=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%cZ=bitcast i8*%cV to i8**
store i8*%cY,i8**%cZ,align 8
%c0=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%c1=getelementptr inbounds i8,i8*%cV,i64 8
%c2=bitcast i8*%c1 to i8**
store i8*%c0,i8**%c2,align 8
%c3=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%c4=getelementptr inbounds i8,i8*%cV,i64 16
%c5=bitcast i8*%c4 to i8**
store i8*%c3,i8**%c5,align 8
%c6=getelementptr inbounds i8,i8*%cV,i64 24
%c7=bitcast i8*%c6 to i32*
store i32 7,i32*%c7,align 4
%c8=call i8*@sml_alloc(i32 inreg 20)#0
%c9=getelementptr inbounds i8,i8*%c8,i64 -4
%da=bitcast i8*%c9 to i32*
store i32 1342177296,i32*%da,align 4
%db=bitcast i8*%c8 to i64*
store i64 0,i64*%db,align 4
%dc=load i8*,i8**%d,align 8
%dd=getelementptr inbounds i8,i8*%c8,i64 8
%de=bitcast i8*%dd to i8**
store i8*%dc,i8**%de,align 8
%df=getelementptr inbounds i8,i8*%c8,i64 16
%dg=bitcast i8*%df to i32*
store i32 2,i32*%dg,align 4
ret i8*%c8
}
define internal fastcc i8*@_SMLLLN16ElaborateForeach12elaborateExpE_58(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
%j=load i8*,i8**%d,align 8
%k=bitcast i8**%c to i8***
%l=load i8**,i8***%k,align 8
br label%m
m:
%n=phi i8**[%l,%i],[%h,%g]
%o=phi i8*[%j,%i],[%b,%g]
%p=bitcast i8*%o to i8**
%q=load i8*,i8**%p,align 8
store i8*%q,i8**%d,align 8
%r=getelementptr inbounds i8,i8*%o,i64 8
%s=bitcast i8*%r to i8**
%t=load i8*,i8**%s,align 8
%u=getelementptr inbounds i8,i8*%t,i64 16
%v=bitcast i8*%u to i8*(i8*,i8*)**
%w=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%v,align 8
%x=bitcast i8*%t to i8**
%y=load i8*,i8**%x,align 8
store i8*null,i8**%c,align 8
%z=load i8*,i8**%n,align 8
%A=call fastcc i8*%w(i8*inreg%y,i8*inreg%z)
store i8*%A,i8**%c,align 8
%B=call i8*@sml_alloc(i32 inreg 20)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177296,i32*%D,align 4
%E=load i8*,i8**%d,align 8
%F=bitcast i8*%B to i8**
store i8*%E,i8**%F,align 8
%G=load i8*,i8**%c,align 8
%H=getelementptr inbounds i8,i8*%B,i64 8
%I=bitcast i8*%H to i8**
store i8*%G,i8**%I,align 8
%J=getelementptr inbounds i8,i8*%B,i64 16
%K=bitcast i8*%J to i32*
store i32 3,i32*%K,align 4
ret i8*%B
}
define internal fastcc i8*@_SMLLLN16ElaborateForeach12elaborateExpE_60(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
s:
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
store i8*%a,i8**%j,align 8
store i8*%b,i8**%c,align 8
%m=load atomic i32,i32*@sml_check_flag unordered,align 4
%n=icmp eq i32%m,0
br i1%n,label%q,label%o
o:
call void@sml_check(i32 inreg%m)
%p=load i8*,i8**%c,align 8
br label%q
q:
%r=phi i8*[%p,%o],[%b,%s]
%t=bitcast i8*%r to i8**
%u=load i8*,i8**%t,align 8
%v=getelementptr inbounds i8,i8*%r,i64 8
%w=bitcast i8*%v to i8**
%x=load i8*,i8**%w,align 8
store i8*%x,i8**%c,align 8
%y=bitcast i8*%u to i32*
%z=load i32,i32*%y,align 4
switch i32%z,label%A[
i32 0,label%fK
i32 1,label%S
]
A:
store i8*null,i8**%j,align 8
call void@sml_matchcomp_bug()
%B=load i8*,i8**@_SMLZ5Match,align 8
store i8*%B,i8**%c,align 8
%C=call i8*@sml_alloc(i32 inreg 20)#0
%D=getelementptr inbounds i8,i8*%C,i64 -4
%E=bitcast i8*%D to i32*
store i32 1342177296,i32*%E,align 4
store i8*%C,i8**%d,align 8
%F=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%G=bitcast i8*%C to i8**
store i8*%F,i8**%G,align 8
%H=getelementptr inbounds i8,i8*%C,i64 8
%I=bitcast i8*%H to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[74x i8]}>,<{[4x i8],i32,[74x i8]}>*@g,i64 0,i32 2,i64 0),i8**%I,align 8
%J=getelementptr inbounds i8,i8*%C,i64 16
%K=bitcast i8*%J to i32*
store i32 3,i32*%K,align 4
%L=call i8*@sml_alloc(i32 inreg 60)#0
%M=getelementptr inbounds i8,i8*%L,i64 -4
%N=bitcast i8*%M to i32*
store i32 1342177336,i32*%N,align 4
%O=getelementptr inbounds i8,i8*%L,i64 56
%P=bitcast i8*%O to i32*
store i32 1,i32*%P,align 4
%Q=load i8*,i8**%d,align 8
%R=bitcast i8*%L to i8**
store i8*%Q,i8**%R,align 8
call void@sml_raise(i8*inreg%L)#1
unreachable
S:
%T=getelementptr inbounds i8,i8*%u,i64 8
%U=bitcast i8*%T to i8**
%V=load i8*,i8**%U,align 8
%W=bitcast i8*%V to i8**
%X=load i8*,i8**%W,align 8
store i8*%X,i8**%d,align 8
%Y=getelementptr inbounds i8,i8*%V,i64 8
%Z=bitcast i8*%Y to i8**
%aa=load i8*,i8**%Z,align 8
store i8*%aa,i8**%e,align 8
%ab=getelementptr inbounds i8,i8*%V,i64 16
%ac=bitcast i8*%ab to i8**
%ad=load i8*,i8**%ac,align 8
store i8*%ad,i8**%f,align 8
%ae=getelementptr inbounds i8,i8*%V,i64 24
%af=bitcast i8*%ae to i8**
%ag=load i8*,i8**%af,align 8
%ah=getelementptr inbounds i8,i8*%V,i64 32
%ai=bitcast i8*%ah to i8**
%aj=load i8*,i8**%ai,align 8
store i8*%aj,i8**%g,align 8
%ak=getelementptr inbounds i8,i8*%V,i64 40
%al=bitcast i8*%ak to i8**
%am=load i8*,i8**%al,align 8
store i8*%am,i8**%h,align 8
%an=load i8*,i8**%j,align 8
%ao=getelementptr inbounds i8,i8*%an,i64 8
%ap=bitcast i8*%ao to i8**
%aq=load i8*,i8**%ap,align 8
%ar=getelementptr inbounds i8,i8*%aq,i64 16
%as=bitcast i8*%ar to i8*(i8*,i8*)**
%at=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%as,align 8
%au=bitcast i8*%aq to i8**
%av=load i8*,i8**%au,align 8
%aw=call fastcc i8*%at(i8*inreg%av,i8*inreg%ag)
store i8*%aw,i8**%i,align 8
%ax=call i8*@sml_alloc(i32 inreg 12)#0
%ay=getelementptr inbounds i8,i8*%ax,i64 -4
%az=bitcast i8*%ay to i32*
store i32 1342177288,i32*%az,align 4
store i8*%ax,i8**%k,align 8
%aA=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%aB=bitcast i8*%ax to i8**
store i8*%aA,i8**%aB,align 8
%aC=getelementptr inbounds i8,i8*%ax,i64 8
%aD=bitcast i8*%aC to i32*
store i32 1,i32*%aD,align 4
%aE=call i8*@sml_alloc(i32 inreg 28)#0
%aF=getelementptr inbounds i8,i8*%aE,i64 -4
%aG=bitcast i8*%aF to i32*
store i32 1342177304,i32*%aG,align 4
store i8*%aE,i8**%i,align 8
%aH=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
%aI=bitcast i8*%aE to i8**
store i8*%aH,i8**%aI,align 8
%aJ=getelementptr inbounds i8,i8*%aE,i64 8
%aK=bitcast i8*%aJ to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3pat_50 to void(...)*),void(...)**%aK,align 8
%aL=getelementptr inbounds i8,i8*%aE,i64 16
%aM=bitcast i8*%aL to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3pat_50 to void(...)*),void(...)**%aM,align 8
%aN=getelementptr inbounds i8,i8*%aE,i64 24
%aO=bitcast i8*%aN to i32*
store i32 -2147483647,i32*%aO,align 4
%aP=call i8*@sml_alloc(i32 inreg 12)#0
%aQ=getelementptr inbounds i8,i8*%aP,i64 -4
%aR=bitcast i8*%aQ to i32*
store i32 1342177288,i32*%aR,align 4
store i8*%aP,i8**%k,align 8
%aS=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aT=bitcast i8*%aP to i8**
store i8*%aS,i8**%aT,align 8
%aU=getelementptr inbounds i8,i8*%aP,i64 8
%aV=bitcast i8*%aU to i32*
store i32 1,i32*%aV,align 4
%aW=call i8*@sml_alloc(i32 inreg 28)#0
%aX=getelementptr inbounds i8,i8*%aW,i64 -4
%aY=bitcast i8*%aX to i32*
store i32 1342177304,i32*%aY,align 4
store i8*%aW,i8**%l,align 8
%aZ=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
%a0=bitcast i8*%aW to i8**
store i8*%aZ,i8**%a0,align 8
%a1=getelementptr inbounds i8,i8*%aW,i64 8
%a2=bitcast i8*%a1 to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL5idPat_51 to void(...)*),void(...)**%a2,align 8
%a3=getelementptr inbounds i8,i8*%aW,i64 16
%a4=bitcast i8*%a3 to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL5idPat_51 to void(...)*),void(...)**%a4,align 8
%a5=getelementptr inbounds i8,i8*%aW,i64 24
%a6=bitcast i8*%a5 to i32*
store i32 -2147483647,i32*%a6,align 4
%a7=call i8*@sml_alloc(i32 inreg 20)#0
%a8=getelementptr inbounds i8,i8*%a7,i64 -4
%a9=bitcast i8*%a8 to i32*
store i32 1342177296,i32*%a9,align 4
store i8*%a7,i8**%k,align 8
%ba=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%bb=bitcast i8*%a7 to i8**
store i8*%ba,i8**%bb,align 8
%bc=getelementptr inbounds i8,i8*%a7,i64 8
%bd=bitcast i8*%bc to i8**
store i8*null,i8**%bd,align 8
%be=getelementptr inbounds i8,i8*%a7,i64 16
%bf=bitcast i8*%be to i32*
store i32 3,i32*%bf,align 4
%bg=call i8*@sml_alloc(i32 inreg 20)#0
%bh=getelementptr inbounds i8,i8*%bg,i64 -4
%bi=bitcast i8*%bh to i32*
store i32 1342177296,i32*%bi,align 4
store i8*%bg,i8**%e,align 8
%bj=load i8*,i8**%l,align 8
store i8*null,i8**%l,align 8
%bk=bitcast i8*%bg to i8**
store i8*%bj,i8**%bk,align 8
%bl=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
%bm=getelementptr inbounds i8,i8*%bg,i64 8
%bn=bitcast i8*%bm to i8**
store i8*%bl,i8**%bn,align 8
%bo=getelementptr inbounds i8,i8*%bg,i64 16
%bp=bitcast i8*%bo to i32*
store i32 3,i32*%bp,align 4
%bq=call fastcc i8*@_SMLFN11RecordLabel9tupleListE(i32 inreg 1,i32 inreg 8)
%br=getelementptr inbounds i8,i8*%bq,i64 16
%bs=bitcast i8*%br to i8*(i8*,i8*)**
%bt=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bs,align 8
%bu=bitcast i8*%bq to i8**
%bv=load i8*,i8**%bu,align 8
%bw=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bx=call fastcc i8*%bt(i8*inreg%bv,i8*inreg%bw)
store i8*%bx,i8**%e,align 8
%by=call i8*@sml_alloc(i32 inreg 12)#0
%bz=getelementptr inbounds i8,i8*%by,i64 -4
%bA=bitcast i8*%bz to i32*
store i32 1342177288,i32*%bA,align 4
store i8*%by,i8**%i,align 8
%bB=load i8*,i8**%e,align 8
%bC=bitcast i8*%by to i8**
store i8*%bB,i8**%bC,align 8
%bD=getelementptr inbounds i8,i8*%by,i64 8
%bE=bitcast i8*%bD to i32*
store i32 1,i32*%bE,align 4
%bF=call i8*@sml_alloc(i32 inreg 28)#0
%bG=getelementptr inbounds i8,i8*%bF,i64 -4
%bH=bitcast i8*%bG to i32*
store i32 1342177304,i32*%bH,align 4
%bI=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%bJ=bitcast i8*%bF to i8**
store i8*%bI,i8**%bJ,align 8
%bK=getelementptr inbounds i8,i8*%bF,i64 8
%bL=bitcast i8*%bK to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3pat_53 to void(...)*),void(...)**%bL,align 8
%bM=getelementptr inbounds i8,i8*%bF,i64 16
%bN=bitcast i8*%bM to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3pat_53 to void(...)*),void(...)**%bN,align 8
%bO=getelementptr inbounds i8,i8*%bF,i64 24
%bP=bitcast i8*%bO to i32*
store i32 -2147483647,i32*%bP,align 4
%bQ=bitcast i8**%j to i8***
%bR=load i8**,i8***%bQ,align 8
%bS=load i8*,i8**%bR,align 8
%bT=getelementptr inbounds i8,i8*%bS,i64 16
%bU=bitcast i8*%bT to i8*(i8*,i8*)**
%bV=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bU,align 8
%bW=bitcast i8*%bS to i8**
%bX=load i8*,i8**%bW,align 8
%bY=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%bZ=call fastcc i8*%bV(i8*inreg%bX,i8*inreg%bY)
store i8*%bZ,i8**%d,align 8
%b0=load i8**,i8***%bQ,align 8
%b1=load i8*,i8**%b0,align 8
%b2=getelementptr inbounds i8,i8*%b1,i64 16
%b3=bitcast i8*%b2 to i8*(i8*,i8*)**
%b4=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%b3,align 8
%b5=bitcast i8*%b1 to i8**
%b6=load i8*,i8**%b5,align 8
%b7=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%b8=call fastcc i8*%b4(i8*inreg%b6,i8*inreg%b7)
store i8*%b8,i8**%h,align 8
%b9=load i8**,i8***%bQ,align 8
%ca=load i8*,i8**%b9,align 8
%cb=getelementptr inbounds i8,i8*%ca,i64 16
%cc=bitcast i8*%cb to i8*(i8*,i8*)**
%cd=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%cc,align 8
%ce=bitcast i8*%ca to i8**
%cf=load i8*,i8**%ce,align 8
%cg=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ch=call fastcc i8*%cd(i8*inreg%cf,i8*inreg%cg)
store i8*%ch,i8**%f,align 8
%ci=call i8*@sml_alloc(i32 inreg 12)#0
%cj=getelementptr inbounds i8,i8*%ci,i64 -4
%ck=bitcast i8*%cj to i32*
store i32 1342177288,i32*%ck,align 4
store i8*%ci,i8**%i,align 8
%cl=load i8*,i8**%f,align 8
%cm=bitcast i8*%ci to i8**
store i8*%cl,i8**%cm,align 8
%cn=getelementptr inbounds i8,i8*%ci,i64 8
%co=bitcast i8*%cn to i32*
store i32 1,i32*%co,align 4
%cp=call i8*@sml_alloc(i32 inreg 28)#0
%cq=getelementptr inbounds i8,i8*%cp,i64 -4
%cr=bitcast i8*%cq to i32*
store i32 1342177304,i32*%cr,align 4
%cs=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%ct=bitcast i8*%cp to i8**
store i8*%cs,i8**%ct,align 8
%cu=getelementptr inbounds i8,i8*%cp,i64 8
%cv=bitcast i8*%cu to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_54 to void(...)*),void(...)**%cv,align 8
%cw=getelementptr inbounds i8,i8*%cp,i64 16
%cx=bitcast i8*%cw to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_54 to void(...)*),void(...)**%cx,align 8
%cy=getelementptr inbounds i8,i8*%cp,i64 24
%cz=bitcast i8*%cy to i32*
store i32 -2147483647,i32*%cz,align 4
%cA=load i8**,i8***%bQ,align 8
%cB=load i8*,i8**%cA,align 8
%cC=getelementptr inbounds i8,i8*%cB,i64 16
%cD=bitcast i8*%cC to i8*(i8*,i8*)**
%cE=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%cD,align 8
store i8*null,i8**%j,align 8
%cF=bitcast i8**%cA to i8***
%cG=load i8**,i8***%cF,align 8
%cH=load i8*,i8**%cG,align 8
%cI=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%cJ=call fastcc i8*%cE(i8*inreg%cH,i8*inreg%cI)
store i8*%cJ,i8**%g,align 8
%cK=call i8*@sml_alloc(i32 inreg 12)#0
%cL=getelementptr inbounds i8,i8*%cK,i64 -4
%cM=bitcast i8*%cL to i32*
store i32 1342177288,i32*%cM,align 4
store i8*%cK,i8**%i,align 8
%cN=load i8*,i8**%g,align 8
%cO=bitcast i8*%cK to i8**
store i8*%cN,i8**%cO,align 8
%cP=getelementptr inbounds i8,i8*%cK,i64 8
%cQ=bitcast i8*%cP to i32*
store i32 1,i32*%cQ,align 4
%cR=call i8*@sml_alloc(i32 inreg 28)#0
%cS=getelementptr inbounds i8,i8*%cR,i64 -4
%cT=bitcast i8*%cS to i32*
store i32 1342177304,i32*%cT,align 4
%cU=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%cV=bitcast i8*%cR to i8**
store i8*%cU,i8**%cV,align 8
%cW=getelementptr inbounds i8,i8*%cR,i64 8
%cX=bitcast i8*%cW to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_55 to void(...)*),void(...)**%cX,align 8
%cY=getelementptr inbounds i8,i8*%cR,i64 16
%cZ=bitcast i8*%cY to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_55 to void(...)*),void(...)**%cZ,align 8
%c0=getelementptr inbounds i8,i8*%cR,i64 24
%c1=bitcast i8*%c0 to i32*
store i32 -2147483647,i32*%c1,align 4
%c2=call i8*@sml_alloc(i32 inreg 36)#0
%c3=getelementptr inbounds i8,i8*%c2,i64 -4
%c4=bitcast i8*%c3 to i32*
store i32 1342177312,i32*%c4,align 4
store i8*%c2,i8**%i,align 8
%c5=load i8*,i8**%e,align 8
%c6=bitcast i8*%c2 to i8**
store i8*%c5,i8**%c6,align 8
%c7=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%c8=getelementptr inbounds i8,i8*%c2,i64 8
%c9=bitcast i8*%c8 to i8**
store i8*%c7,i8**%c9,align 8
%da=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%db=getelementptr inbounds i8,i8*%c2,i64 16
%dc=bitcast i8*%db to i8**
store i8*%da,i8**%dc,align 8
%dd=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%de=getelementptr inbounds i8,i8*%c2,i64 24
%df=bitcast i8*%de to i8**
store i8*%dd,i8**%df,align 8
%dg=getelementptr inbounds i8,i8*%c2,i64 32
%dh=bitcast i8*%dg to i32*
store i32 15,i32*%dh,align 4
%di=call i8*@sml_alloc(i32 inreg 28)#0
%dj=getelementptr inbounds i8,i8*%di,i64 -4
%dk=bitcast i8*%dj to i32*
store i32 1342177304,i32*%dk,align 4
%dl=load i8*,i8**%i,align 8
%dm=bitcast i8*%di to i8**
store i8*%dl,i8**%dm,align 8
%dn=getelementptr inbounds i8,i8*%di,i64 8
%do=bitcast i8*%dn to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_57 to void(...)*),void(...)**%do,align 8
%dp=getelementptr inbounds i8,i8*%di,i64 16
%dq=bitcast i8*%dp to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_57 to void(...)*),void(...)**%dq,align 8
%dr=getelementptr inbounds i8,i8*%di,i64 24
%ds=bitcast i8*%dr to i32*
store i32 -2147483647,i32*%ds,align 4
%dt=load i8*,i8**%c,align 8
store i8*null,i8**%i,align 8
%du=call fastcc i8*@_SMLLLN16ElaborateForeach12elaborateExpE_57(i8*inreg%dl,i8*inreg%dt)
store i8*%du,i8**%d,align 8
%dv=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%dw=getelementptr inbounds i8,i8*%dv,i64 16
%dx=bitcast i8*%dw to i8*(i8*,i8*)**
%dy=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%dx,align 8
%dz=bitcast i8*%dv to i8**
%dA=load i8*,i8**%dz,align 8
store i8*%dA,i8**%f,align 8
%dB=call i8*@sml_alloc(i32 inreg 12)#0
%dC=getelementptr inbounds i8,i8*%dB,i64 -4
%dD=bitcast i8*%dC to i32*
store i32 1342177288,i32*%dD,align 4
store i8*%dB,i8**%h,align 8
%dE=load i8*,i8**%c,align 8
%dF=bitcast i8*%dB to i8**
store i8*%dE,i8**%dF,align 8
%dG=getelementptr inbounds i8,i8*%dB,i64 8
%dH=bitcast i8*%dG to i32*
store i32 1,i32*%dH,align 4
%dI=call i8*@sml_alloc(i32 inreg 28)#0
%dJ=getelementptr inbounds i8,i8*%dI,i64 -4
%dK=bitcast i8*%dJ to i32*
store i32 1342177304,i32*%dK,align 4
%dL=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%dM=bitcast i8*%dI to i8**
store i8*%dL,i8**%dM,align 8
%dN=getelementptr inbounds i8,i8*%dI,i64 8
%dO=bitcast i8*%dN to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_58 to void(...)*),void(...)**%dO,align 8
%dP=getelementptr inbounds i8,i8*%dI,i64 16
%dQ=bitcast i8*%dP to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_58 to void(...)*),void(...)**%dQ,align 8
%dR=getelementptr inbounds i8,i8*%dI,i64 24
%dS=bitcast i8*%dR to i32*
store i32 -2147483647,i32*%dS,align 4
%dT=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%dU=call fastcc i8*%dy(i8*inreg%dT,i8*inreg%dI)
%dV=getelementptr inbounds i8,i8*%dU,i64 16
%dW=bitcast i8*%dV to i8*(i8*,i8*)**
%dX=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%dW,align 8
%dY=bitcast i8*%dU to i8**
%dZ=load i8*,i8**%dY,align 8
%d0=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%d1=call fastcc i8*%dX(i8*inreg%dZ,i8*inreg%d0)
store i8*%d1,i8**%e,align 8
%d2=call i8*@sml_alloc(i32 inreg 28)#0
%d3=getelementptr inbounds i8,i8*%d2,i64 -4
%d4=bitcast i8*%d3 to i32*
store i32 1342177304,i32*%d4,align 4
store i8*%d2,i8**%f,align 8
%d5=bitcast i8*%d2 to i64*
store i64 0,i64*%d5,align 4
%d6=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%d7=getelementptr inbounds i8,i8*%d2,i64 8
%d8=bitcast i8*%d7 to i8**
store i8*%d6,i8**%d8,align 8
%d9=load i8*,i8**%c,align 8
%ea=getelementptr inbounds i8,i8*%d2,i64 16
%eb=bitcast i8*%ea to i8**
store i8*%d9,i8**%eb,align 8
%ec=getelementptr inbounds i8,i8*%d2,i64 24
%ed=bitcast i8*%ec to i32*
store i32 6,i32*%ed,align 4
%ee=call i8*@sml_alloc(i32 inreg 20)#0
%ef=getelementptr inbounds i8,i8*%ee,i64 -4
%eg=bitcast i8*%ef to i32*
store i32 1342177296,i32*%eg,align 4
store i8*%ee,i8**%e,align 8
%eh=getelementptr inbounds i8,i8*%ee,i64 4
%ei=bitcast i8*%eh to i32*
store i32 0,i32*%ei,align 1
%ej=bitcast i8*%ee to i32*
store i32 4,i32*%ej,align 4
%ek=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%el=getelementptr inbounds i8,i8*%ee,i64 8
%em=bitcast i8*%el to i8**
store i8*%ek,i8**%em,align 8
%en=getelementptr inbounds i8,i8*%ee,i64 16
%eo=bitcast i8*%en to i32*
store i32 2,i32*%eo,align 4
%ep=call i8*@sml_alloc(i32 inreg 20)#0
%eq=getelementptr inbounds i8,i8*%ep,i64 -4
%er=bitcast i8*%eq to i32*
store i32 1342177296,i32*%er,align 4
store i8*%ep,i8**%f,align 8
%es=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%et=bitcast i8*%ep to i8**
store i8*%es,i8**%et,align 8
%eu=getelementptr inbounds i8,i8*%ep,i64 8
%ev=bitcast i8*%eu to i8**
store i8*null,i8**%ev,align 8
%ew=getelementptr inbounds i8,i8*%ep,i64 16
%ex=bitcast i8*%ew to i32*
store i32 3,i32*%ex,align 4
%ey=call i8*@sml_alloc(i32 inreg 28)#0
%ez=getelementptr inbounds i8,i8*%ey,i64 -4
%eA=bitcast i8*%ez to i32*
store i32 1342177304,i32*%eA,align 4
store i8*%ey,i8**%e,align 8
%eB=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%eC=bitcast i8*%ey to i8**
store i8*%eB,i8**%eC,align 8
%eD=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%eE=getelementptr inbounds i8,i8*%ey,i64 8
%eF=bitcast i8*%eE to i8**
store i8*%eD,i8**%eF,align 8
%eG=load i8*,i8**%c,align 8
%eH=getelementptr inbounds i8,i8*%ey,i64 16
%eI=bitcast i8*%eH to i8**
store i8*%eG,i8**%eI,align 8
%eJ=getelementptr inbounds i8,i8*%ey,i64 24
%eK=bitcast i8*%eJ to i32*
store i32 7,i32*%eK,align 4
%eL=call i8*@sml_alloc(i32 inreg 20)#0
%eM=getelementptr inbounds i8,i8*%eL,i64 -4
%eN=bitcast i8*%eM to i32*
store i32 1342177296,i32*%eN,align 4
store i8*%eL,i8**%f,align 8
%eO=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%eP=bitcast i8*%eL to i8**
store i8*%eO,i8**%eP,align 8
%eQ=getelementptr inbounds i8,i8*%eL,i64 8
%eR=bitcast i8*%eQ to i8**
store i8*null,i8**%eR,align 8
%eS=getelementptr inbounds i8,i8*%eL,i64 16
%eT=bitcast i8*%eS to i32*
store i32 3,i32*%eT,align 4
%eU=call i8*@sml_alloc(i32 inreg 20)#0
%eV=getelementptr inbounds i8,i8*%eU,i64 -4
%eW=bitcast i8*%eV to i32*
store i32 1342177296,i32*%eW,align 4
store i8*%eU,i8**%e,align 8
%eX=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%eY=bitcast i8*%eU to i8**
store i8*%eX,i8**%eY,align 8
%eZ=load i8*,i8**%c,align 8
%e0=getelementptr inbounds i8,i8*%eU,i64 8
%e1=bitcast i8*%e0 to i8**
store i8*%eZ,i8**%e1,align 8
%e2=getelementptr inbounds i8,i8*%eU,i64 16
%e3=bitcast i8*%e2 to i32*
store i32 3,i32*%e3,align 4
%e4=call i8*@sml_alloc(i32 inreg 20)#0
%e5=getelementptr inbounds i8,i8*%e4,i64 -4
%e6=bitcast i8*%e5 to i32*
store i32 1342177296,i32*%e6,align 4
store i8*%e4,i8**%f,align 8
%e7=getelementptr inbounds i8,i8*%e4,i64 4
%e8=bitcast i8*%e7 to i32*
store i32 0,i32*%e8,align 1
%e9=bitcast i8*%e4 to i32*
store i32 10,i32*%e9,align 4
%fa=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%fb=getelementptr inbounds i8,i8*%e4,i64 8
%fc=bitcast i8*%fb to i8**
store i8*%fa,i8**%fc,align 8
%fd=getelementptr inbounds i8,i8*%e4,i64 16
%fe=bitcast i8*%fd to i32*
store i32 2,i32*%fe,align 4
%ff=call i8*@sml_alloc(i32 inreg 20)#0
%fg=getelementptr inbounds i8,i8*%ff,i64 -4
%fh=bitcast i8*%fg to i32*
store i32 1342177296,i32*%fh,align 4
store i8*%ff,i8**%g,align 8
%fi=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%fj=bitcast i8*%ff to i8**
store i8*%fi,i8**%fj,align 8
%fk=getelementptr inbounds i8,i8*%ff,i64 8
%fl=bitcast i8*%fk to i8**
store i8*null,i8**%fl,align 8
%fm=getelementptr inbounds i8,i8*%ff,i64 16
%fn=bitcast i8*%fm to i32*
store i32 3,i32*%fn,align 4
%fo=call i8*@sml_alloc(i32 inreg 28)#0
%fp=getelementptr inbounds i8,i8*%fo,i64 -4
%fq=bitcast i8*%fp to i32*
store i32 1342177304,i32*%fq,align 4
store i8*%fo,i8**%e,align 8
%fr=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%fs=bitcast i8*%fo to i8**
store i8*%fr,i8**%fs,align 8
%ft=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%fu=getelementptr inbounds i8,i8*%fo,i64 8
%fv=bitcast i8*%fu to i8**
store i8*%ft,i8**%fv,align 8
%fw=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%fx=getelementptr inbounds i8,i8*%fo,i64 16
%fy=bitcast i8*%fx to i8**
store i8*%fw,i8**%fy,align 8
%fz=getelementptr inbounds i8,i8*%fo,i64 24
%fA=bitcast i8*%fz to i32*
store i32 7,i32*%fA,align 4
%fB=call i8*@sml_alloc(i32 inreg 20)#0
%fC=getelementptr inbounds i8,i8*%fB,i64 -4
%fD=bitcast i8*%fC to i32*
store i32 1342177296,i32*%fD,align 4
%fE=bitcast i8*%fB to i64*
store i64 0,i64*%fE,align 4
%fF=load i8*,i8**%e,align 8
%fG=getelementptr inbounds i8,i8*%fB,i64 8
%fH=bitcast i8*%fG to i8**
store i8*%fF,i8**%fH,align 8
%fI=getelementptr inbounds i8,i8*%fB,i64 16
%fJ=bitcast i8*%fI to i32*
store i32 2,i32*%fJ,align 4
ret i8*%fB
fK:
%fL=getelementptr inbounds i8,i8*%u,i64 8
%fM=bitcast i8*%fL to i8**
%fN=load i8*,i8**%fM,align 8
%fO=bitcast i8*%fN to i8**
%fP=load i8*,i8**%fO,align 8
store i8*%fP,i8**%d,align 8
%fQ=getelementptr inbounds i8,i8*%fN,i64 8
%fR=bitcast i8*%fQ to i8**
%fS=load i8*,i8**%fR,align 8
store i8*%fS,i8**%e,align 8
%fT=getelementptr inbounds i8,i8*%fN,i64 16
%fU=bitcast i8*%fT to i8**
%fV=load i8*,i8**%fU,align 8
store i8*%fV,i8**%f,align 8
%fW=getelementptr inbounds i8,i8*%fN,i64 24
%fX=bitcast i8*%fW to i8**
%fY=load i8*,i8**%fX,align 8
%fZ=getelementptr inbounds i8,i8*%fN,i64 32
%f0=bitcast i8*%fZ to i8**
%f1=load i8*,i8**%f0,align 8
store i8*%f1,i8**%g,align 8
%f2=load i8*,i8**%j,align 8
%f3=getelementptr inbounds i8,i8*%f2,i64 8
%f4=bitcast i8*%f3 to i8**
%f5=load i8*,i8**%f4,align 8
%f6=getelementptr inbounds i8,i8*%f5,i64 16
%f7=bitcast i8*%f6 to i8*(i8*,i8*)**
%f8=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%f7,align 8
%f9=bitcast i8*%f5 to i8**
%ga=load i8*,i8**%f9,align 8
%gb=call fastcc i8*%f8(i8*inreg%ga,i8*inreg%fY)
store i8*%gb,i8**%h,align 8
%gc=call i8*@sml_alloc(i32 inreg 12)#0
%gd=getelementptr inbounds i8,i8*%gc,i64 -4
%ge=bitcast i8*%gd to i32*
store i32 1342177288,i32*%ge,align 4
store i8*%gc,i8**%i,align 8
%gf=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%gg=bitcast i8*%gc to i8**
store i8*%gf,i8**%gg,align 8
%gh=getelementptr inbounds i8,i8*%gc,i64 8
%gi=bitcast i8*%gh to i32*
store i32 1,i32*%gi,align 4
%gj=call i8*@sml_alloc(i32 inreg 28)#0
%gk=getelementptr inbounds i8,i8*%gj,i64 -4
%gl=bitcast i8*%gk to i32*
store i32 1342177304,i32*%gl,align 4
store i8*%gj,i8**%h,align 8
%gm=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%gn=bitcast i8*%gj to i8**
store i8*%gm,i8**%gn,align 8
%go=getelementptr inbounds i8,i8*%gj,i64 8
%gp=bitcast i8*%go to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3pat_41 to void(...)*),void(...)**%gp,align 8
%gq=getelementptr inbounds i8,i8*%gj,i64 16
%gr=bitcast i8*%gq to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3pat_41 to void(...)*),void(...)**%gr,align 8
%gs=getelementptr inbounds i8,i8*%gj,i64 24
%gt=bitcast i8*%gs to i32*
store i32 -2147483647,i32*%gt,align 4
%gu=call i8*@sml_alloc(i32 inreg 12)#0
%gv=getelementptr inbounds i8,i8*%gu,i64 -4
%gw=bitcast i8*%gv to i32*
store i32 1342177288,i32*%gw,align 4
store i8*%gu,i8**%i,align 8
%gx=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%gy=bitcast i8*%gu to i8**
store i8*%gx,i8**%gy,align 8
%gz=getelementptr inbounds i8,i8*%gu,i64 8
%gA=bitcast i8*%gz to i32*
store i32 1,i32*%gA,align 4
%gB=call i8*@sml_alloc(i32 inreg 28)#0
%gC=getelementptr inbounds i8,i8*%gB,i64 -4
%gD=bitcast i8*%gC to i32*
store i32 1342177304,i32*%gD,align 4
store i8*%gB,i8**%k,align 8
%gE=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%gF=bitcast i8*%gB to i8**
store i8*%gE,i8**%gF,align 8
%gG=getelementptr inbounds i8,i8*%gB,i64 8
%gH=bitcast i8*%gG to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL5idPat_42 to void(...)*),void(...)**%gH,align 8
%gI=getelementptr inbounds i8,i8*%gB,i64 16
%gJ=bitcast i8*%gI to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL5idPat_42 to void(...)*),void(...)**%gJ,align 8
%gK=getelementptr inbounds i8,i8*%gB,i64 24
%gL=bitcast i8*%gK to i32*
store i32 -2147483647,i32*%gL,align 4
%gM=call i8*@sml_alloc(i32 inreg 20)#0
%gN=getelementptr inbounds i8,i8*%gM,i64 -4
%gO=bitcast i8*%gN to i32*
store i32 1342177296,i32*%gO,align 4
store i8*%gM,i8**%i,align 8
%gP=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%gQ=bitcast i8*%gM to i8**
store i8*%gP,i8**%gQ,align 8
%gR=getelementptr inbounds i8,i8*%gM,i64 8
%gS=bitcast i8*%gR to i8**
store i8*null,i8**%gS,align 8
%gT=getelementptr inbounds i8,i8*%gM,i64 16
%gU=bitcast i8*%gT to i32*
store i32 3,i32*%gU,align 4
%gV=call i8*@sml_alloc(i32 inreg 20)#0
%gW=getelementptr inbounds i8,i8*%gV,i64 -4
%gX=bitcast i8*%gW to i32*
store i32 1342177296,i32*%gX,align 4
store i8*%gV,i8**%e,align 8
%gY=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
%gZ=bitcast i8*%gV to i8**
store i8*%gY,i8**%gZ,align 8
%g0=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%g1=getelementptr inbounds i8,i8*%gV,i64 8
%g2=bitcast i8*%g1 to i8**
store i8*%g0,i8**%g2,align 8
%g3=getelementptr inbounds i8,i8*%gV,i64 16
%g4=bitcast i8*%g3 to i32*
store i32 3,i32*%g4,align 4
%g5=call fastcc i8*@_SMLFN11RecordLabel9tupleListE(i32 inreg 1,i32 inreg 8)
%g6=getelementptr inbounds i8,i8*%g5,i64 16
%g7=bitcast i8*%g6 to i8*(i8*,i8*)**
%g8=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%g7,align 8
%g9=bitcast i8*%g5 to i8**
%ha=load i8*,i8**%g9,align 8
%hb=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%hc=call fastcc i8*%g8(i8*inreg%ha,i8*inreg%hb)
store i8*%hc,i8**%e,align 8
%hd=call i8*@sml_alloc(i32 inreg 12)#0
%he=getelementptr inbounds i8,i8*%hd,i64 -4
%hf=bitcast i8*%he to i32*
store i32 1342177288,i32*%hf,align 4
store i8*%hd,i8**%h,align 8
%hg=load i8*,i8**%e,align 8
%hh=bitcast i8*%hd to i8**
store i8*%hg,i8**%hh,align 8
%hi=getelementptr inbounds i8,i8*%hd,i64 8
%hj=bitcast i8*%hi to i32*
store i32 1,i32*%hj,align 4
%hk=call i8*@sml_alloc(i32 inreg 28)#0
%hl=getelementptr inbounds i8,i8*%hk,i64 -4
%hm=bitcast i8*%hl to i32*
store i32 1342177304,i32*%hm,align 4
%hn=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%ho=bitcast i8*%hk to i8**
store i8*%hn,i8**%ho,align 8
%hp=getelementptr inbounds i8,i8*%hk,i64 8
%hq=bitcast i8*%hp to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3pat_44 to void(...)*),void(...)**%hq,align 8
%hr=getelementptr inbounds i8,i8*%hk,i64 16
%hs=bitcast i8*%hr to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLL3pat_44 to void(...)*),void(...)**%hs,align 8
%ht=getelementptr inbounds i8,i8*%hk,i64 24
%hu=bitcast i8*%ht to i32*
store i32 -2147483647,i32*%hu,align 4
%hv=bitcast i8**%j to i8***
%hw=load i8**,i8***%hv,align 8
%hx=load i8*,i8**%hw,align 8
%hy=getelementptr inbounds i8,i8*%hx,i64 16
%hz=bitcast i8*%hy to i8*(i8*,i8*)**
%hA=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%hz,align 8
%hB=bitcast i8*%hx to i8**
%hC=load i8*,i8**%hB,align 8
%hD=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%hE=call fastcc i8*%hA(i8*inreg%hC,i8*inreg%hD)
store i8*%hE,i8**%d,align 8
%hF=load i8**,i8***%hv,align 8
%hG=load i8*,i8**%hF,align 8
%hH=getelementptr inbounds i8,i8*%hG,i64 16
%hI=bitcast i8*%hH to i8*(i8*,i8*)**
%hJ=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%hI,align 8
%hK=bitcast i8*%hG to i8**
%hL=load i8*,i8**%hK,align 8
%hM=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%hN=call fastcc i8*%hJ(i8*inreg%hL,i8*inreg%hM)
store i8*%hN,i8**%f,align 8
%hO=call i8*@sml_alloc(i32 inreg 12)#0
%hP=getelementptr inbounds i8,i8*%hO,i64 -4
%hQ=bitcast i8*%hP to i32*
store i32 1342177288,i32*%hQ,align 4
store i8*%hO,i8**%h,align 8
%hR=load i8*,i8**%f,align 8
%hS=bitcast i8*%hO to i8**
store i8*%hR,i8**%hS,align 8
%hT=getelementptr inbounds i8,i8*%hO,i64 8
%hU=bitcast i8*%hT to i32*
store i32 1,i32*%hU,align 4
%hV=call i8*@sml_alloc(i32 inreg 28)#0
%hW=getelementptr inbounds i8,i8*%hV,i64 -4
%hX=bitcast i8*%hW to i32*
store i32 1342177304,i32*%hX,align 4
%hY=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%hZ=bitcast i8*%hV to i8**
store i8*%hY,i8**%hZ,align 8
%h0=getelementptr inbounds i8,i8*%hV,i64 8
%h1=bitcast i8*%h0 to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_45 to void(...)*),void(...)**%h1,align 8
%h2=getelementptr inbounds i8,i8*%hV,i64 16
%h3=bitcast i8*%h2 to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_45 to void(...)*),void(...)**%h3,align 8
%h4=getelementptr inbounds i8,i8*%hV,i64 24
%h5=bitcast i8*%h4 to i32*
store i32 -2147483647,i32*%h5,align 4
%h6=load i8**,i8***%hv,align 8
%h7=load i8*,i8**%h6,align 8
%h8=getelementptr inbounds i8,i8*%h7,i64 16
%h9=bitcast i8*%h8 to i8*(i8*,i8*)**
%ia=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%h9,align 8
store i8*null,i8**%j,align 8
%ib=bitcast i8**%h6 to i8***
%ic=load i8**,i8***%ib,align 8
%id=load i8*,i8**%ic,align 8
%ie=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%if=call fastcc i8*%ia(i8*inreg%id,i8*inreg%ie)
store i8*%if,i8**%g,align 8
%ig=call i8*@sml_alloc(i32 inreg 12)#0
%ih=getelementptr inbounds i8,i8*%ig,i64 -4
%ii=bitcast i8*%ih to i32*
store i32 1342177288,i32*%ii,align 4
store i8*%ig,i8**%h,align 8
%ij=load i8*,i8**%g,align 8
%ik=bitcast i8*%ig to i8**
store i8*%ij,i8**%ik,align 8
%il=getelementptr inbounds i8,i8*%ig,i64 8
%im=bitcast i8*%il to i32*
store i32 1,i32*%im,align 4
%in=call i8*@sml_alloc(i32 inreg 28)#0
%io=getelementptr inbounds i8,i8*%in,i64 -4
%ip=bitcast i8*%io to i32*
store i32 1342177304,i32*%ip,align 4
%iq=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%ir=bitcast i8*%in to i8**
store i8*%iq,i8**%ir,align 8
%is=getelementptr inbounds i8,i8*%in,i64 8
%it=bitcast i8*%is to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_46 to void(...)*),void(...)**%it,align 8
%iu=getelementptr inbounds i8,i8*%in,i64 16
%iv=bitcast i8*%iu to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_46 to void(...)*),void(...)**%iv,align 8
%iw=getelementptr inbounds i8,i8*%in,i64 24
%ix=bitcast i8*%iw to i32*
store i32 -2147483647,i32*%ix,align 4
%iy=call i8*@sml_alloc(i32 inreg 28)#0
%iz=getelementptr inbounds i8,i8*%iy,i64 -4
%iA=bitcast i8*%iz to i32*
store i32 1342177304,i32*%iA,align 4
store i8*%iy,i8**%h,align 8
%iB=load i8*,i8**%e,align 8
%iC=bitcast i8*%iy to i8**
store i8*%iB,i8**%iC,align 8
%iD=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%iE=getelementptr inbounds i8,i8*%iy,i64 8
%iF=bitcast i8*%iE to i8**
store i8*%iD,i8**%iF,align 8
%iG=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%iH=getelementptr inbounds i8,i8*%iy,i64 16
%iI=bitcast i8*%iH to i8**
store i8*%iG,i8**%iI,align 8
%iJ=getelementptr inbounds i8,i8*%iy,i64 24
%iK=bitcast i8*%iJ to i32*
store i32 7,i32*%iK,align 4
%iL=call i8*@sml_alloc(i32 inreg 28)#0
%iM=getelementptr inbounds i8,i8*%iL,i64 -4
%iN=bitcast i8*%iM to i32*
store i32 1342177304,i32*%iN,align 4
%iO=load i8*,i8**%h,align 8
%iP=bitcast i8*%iL to i8**
store i8*%iO,i8**%iP,align 8
%iQ=getelementptr inbounds i8,i8*%iL,i64 8
%iR=bitcast i8*%iQ to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_48 to void(...)*),void(...)**%iR,align 8
%iS=getelementptr inbounds i8,i8*%iL,i64 16
%iT=bitcast i8*%iS to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_48 to void(...)*),void(...)**%iT,align 8
%iU=getelementptr inbounds i8,i8*%iL,i64 24
%iV=bitcast i8*%iU to i32*
store i32 -2147483647,i32*%iV,align 4
%iW=load i8*,i8**%c,align 8
store i8*null,i8**%h,align 8
%iX=call fastcc i8*@_SMLLLN16ElaborateForeach12elaborateExpE_48(i8*inreg%iO,i8*inreg%iW)
store i8*%iX,i8**%d,align 8
%iY=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%iZ=getelementptr inbounds i8,i8*%iY,i64 16
%i0=bitcast i8*%iZ to i8*(i8*,i8*)**
%i1=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%i0,align 8
%i2=bitcast i8*%iY to i8**
%i3=load i8*,i8**%i2,align 8
store i8*%i3,i8**%f,align 8
%i4=call i8*@sml_alloc(i32 inreg 12)#0
%i5=getelementptr inbounds i8,i8*%i4,i64 -4
%i6=bitcast i8*%i5 to i32*
store i32 1342177288,i32*%i6,align 4
store i8*%i4,i8**%h,align 8
%i7=load i8*,i8**%c,align 8
%i8=bitcast i8*%i4 to i8**
store i8*%i7,i8**%i8,align 8
%i9=getelementptr inbounds i8,i8*%i4,i64 8
%ja=bitcast i8*%i9 to i32*
store i32 1,i32*%ja,align 4
%jb=call i8*@sml_alloc(i32 inreg 28)#0
%jc=getelementptr inbounds i8,i8*%jb,i64 -4
%jd=bitcast i8*%jc to i32*
store i32 1342177304,i32*%jd,align 4
%je=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%jf=bitcast i8*%jb to i8**
store i8*%je,i8**%jf,align 8
%jg=getelementptr inbounds i8,i8*%jb,i64 8
%jh=bitcast i8*%jg to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_49 to void(...)*),void(...)**%jh,align 8
%ji=getelementptr inbounds i8,i8*%jb,i64 16
%jj=bitcast i8*%ji to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_49 to void(...)*),void(...)**%jj,align 8
%jk=getelementptr inbounds i8,i8*%jb,i64 24
%jl=bitcast i8*%jk to i32*
store i32 -2147483647,i32*%jl,align 4
%jm=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%jn=call fastcc i8*%i1(i8*inreg%jm,i8*inreg%jb)
%jo=getelementptr inbounds i8,i8*%jn,i64 16
%jp=bitcast i8*%jo to i8*(i8*,i8*)**
%jq=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%jp,align 8
%jr=bitcast i8*%jn to i8**
%js=load i8*,i8**%jr,align 8
%jt=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ju=call fastcc i8*%jq(i8*inreg%js,i8*inreg%jt)
store i8*%ju,i8**%e,align 8
%jv=call i8*@sml_alloc(i32 inreg 28)#0
%jw=getelementptr inbounds i8,i8*%jv,i64 -4
%jx=bitcast i8*%jw to i32*
store i32 1342177304,i32*%jx,align 4
store i8*%jv,i8**%f,align 8
%jy=bitcast i8*%jv to i64*
store i64 0,i64*%jy,align 4
%jz=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%jA=getelementptr inbounds i8,i8*%jv,i64 8
%jB=bitcast i8*%jA to i8**
store i8*%jz,i8**%jB,align 8
%jC=load i8*,i8**%c,align 8
%jD=getelementptr inbounds i8,i8*%jv,i64 16
%jE=bitcast i8*%jD to i8**
store i8*%jC,i8**%jE,align 8
%jF=getelementptr inbounds i8,i8*%jv,i64 24
%jG=bitcast i8*%jF to i32*
store i32 6,i32*%jG,align 4
%jH=call i8*@sml_alloc(i32 inreg 20)#0
%jI=getelementptr inbounds i8,i8*%jH,i64 -4
%jJ=bitcast i8*%jI to i32*
store i32 1342177296,i32*%jJ,align 4
store i8*%jH,i8**%e,align 8
%jK=getelementptr inbounds i8,i8*%jH,i64 4
%jL=bitcast i8*%jK to i32*
store i32 0,i32*%jL,align 1
%jM=bitcast i8*%jH to i32*
store i32 4,i32*%jM,align 4
%jN=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%jO=getelementptr inbounds i8,i8*%jH,i64 8
%jP=bitcast i8*%jO to i8**
store i8*%jN,i8**%jP,align 8
%jQ=getelementptr inbounds i8,i8*%jH,i64 16
%jR=bitcast i8*%jQ to i32*
store i32 2,i32*%jR,align 4
%jS=call i8*@sml_alloc(i32 inreg 20)#0
%jT=getelementptr inbounds i8,i8*%jS,i64 -4
%jU=bitcast i8*%jT to i32*
store i32 1342177296,i32*%jU,align 4
store i8*%jS,i8**%f,align 8
%jV=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%jW=bitcast i8*%jS to i8**
store i8*%jV,i8**%jW,align 8
%jX=getelementptr inbounds i8,i8*%jS,i64 8
%jY=bitcast i8*%jX to i8**
store i8*null,i8**%jY,align 8
%jZ=getelementptr inbounds i8,i8*%jS,i64 16
%j0=bitcast i8*%jZ to i32*
store i32 3,i32*%j0,align 4
%j1=call i8*@sml_alloc(i32 inreg 28)#0
%j2=getelementptr inbounds i8,i8*%j1,i64 -4
%j3=bitcast i8*%j2 to i32*
store i32 1342177304,i32*%j3,align 4
store i8*%j1,i8**%e,align 8
%j4=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%j5=bitcast i8*%j1 to i8**
store i8*%j4,i8**%j5,align 8
%j6=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%j7=getelementptr inbounds i8,i8*%j1,i64 8
%j8=bitcast i8*%j7 to i8**
store i8*%j6,i8**%j8,align 8
%j9=load i8*,i8**%c,align 8
%ka=getelementptr inbounds i8,i8*%j1,i64 16
%kb=bitcast i8*%ka to i8**
store i8*%j9,i8**%kb,align 8
%kc=getelementptr inbounds i8,i8*%j1,i64 24
%kd=bitcast i8*%kc to i32*
store i32 7,i32*%kd,align 4
%ke=call i8*@sml_alloc(i32 inreg 20)#0
%kf=getelementptr inbounds i8,i8*%ke,i64 -4
%kg=bitcast i8*%kf to i32*
store i32 1342177296,i32*%kg,align 4
store i8*%ke,i8**%f,align 8
%kh=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ki=bitcast i8*%ke to i8**
store i8*%kh,i8**%ki,align 8
%kj=getelementptr inbounds i8,i8*%ke,i64 8
%kk=bitcast i8*%kj to i8**
store i8*null,i8**%kk,align 8
%kl=getelementptr inbounds i8,i8*%ke,i64 16
%km=bitcast i8*%kl to i32*
store i32 3,i32*%km,align 4
%kn=call i8*@sml_alloc(i32 inreg 20)#0
%ko=getelementptr inbounds i8,i8*%kn,i64 -4
%kp=bitcast i8*%ko to i32*
store i32 1342177296,i32*%kp,align 4
store i8*%kn,i8**%e,align 8
%kq=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%kr=bitcast i8*%kn to i8**
store i8*%kq,i8**%kr,align 8
%ks=load i8*,i8**%c,align 8
%kt=getelementptr inbounds i8,i8*%kn,i64 8
%ku=bitcast i8*%kt to i8**
store i8*%ks,i8**%ku,align 8
%kv=getelementptr inbounds i8,i8*%kn,i64 16
%kw=bitcast i8*%kv to i32*
store i32 3,i32*%kw,align 4
%kx=call i8*@sml_alloc(i32 inreg 20)#0
%ky=getelementptr inbounds i8,i8*%kx,i64 -4
%kz=bitcast i8*%ky to i32*
store i32 1342177296,i32*%kz,align 4
store i8*%kx,i8**%f,align 8
%kA=getelementptr inbounds i8,i8*%kx,i64 4
%kB=bitcast i8*%kA to i32*
store i32 0,i32*%kB,align 1
%kC=bitcast i8*%kx to i32*
store i32 10,i32*%kC,align 4
%kD=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%kE=getelementptr inbounds i8,i8*%kx,i64 8
%kF=bitcast i8*%kE to i8**
store i8*%kD,i8**%kF,align 8
%kG=getelementptr inbounds i8,i8*%kx,i64 16
%kH=bitcast i8*%kG to i32*
store i32 2,i32*%kH,align 4
%kI=call i8*@sml_alloc(i32 inreg 20)#0
%kJ=getelementptr inbounds i8,i8*%kI,i64 -4
%kK=bitcast i8*%kJ to i32*
store i32 1342177296,i32*%kK,align 4
store i8*%kI,i8**%g,align 8
%kL=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%kM=bitcast i8*%kI to i8**
store i8*%kL,i8**%kM,align 8
%kN=getelementptr inbounds i8,i8*%kI,i64 8
%kO=bitcast i8*%kN to i8**
store i8*null,i8**%kO,align 8
%kP=getelementptr inbounds i8,i8*%kI,i64 16
%kQ=bitcast i8*%kP to i32*
store i32 3,i32*%kQ,align 4
%kR=call i8*@sml_alloc(i32 inreg 28)#0
%kS=getelementptr inbounds i8,i8*%kR,i64 -4
%kT=bitcast i8*%kS to i32*
store i32 1342177304,i32*%kT,align 4
store i8*%kR,i8**%e,align 8
%kU=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%kV=bitcast i8*%kR to i8**
store i8*%kU,i8**%kV,align 8
%kW=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%kX=getelementptr inbounds i8,i8*%kR,i64 8
%kY=bitcast i8*%kX to i8**
store i8*%kW,i8**%kY,align 8
%kZ=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%k0=getelementptr inbounds i8,i8*%kR,i64 16
%k1=bitcast i8*%k0 to i8**
store i8*%kZ,i8**%k1,align 8
%k2=getelementptr inbounds i8,i8*%kR,i64 24
%k3=bitcast i8*%k2 to i32*
store i32 7,i32*%k3,align 4
%k4=call i8*@sml_alloc(i32 inreg 20)#0
%k5=getelementptr inbounds i8,i8*%k4,i64 -4
%k6=bitcast i8*%k5 to i32*
store i32 1342177296,i32*%k6,align 4
%k7=bitcast i8*%k4 to i64*
store i64 0,i64*%k7,align 4
%k8=load i8*,i8**%e,align 8
%k9=getelementptr inbounds i8,i8*%k4,i64 8
%la=bitcast i8*%k9 to i8**
store i8*%k8,i8**%la,align 8
%lb=getelementptr inbounds i8,i8*%k4,i64 16
%lc=bitcast i8*%lb to i32*
store i32 2,i32*%lc,align 4
ret i8*%k4
}
define fastcc i8*@_SMLFN16ElaborateForeach12elaborateExpE(i8*inreg%a)#4 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
%e=bitcast i8*%a to i8**
%f=load i8*,i8**%e,align 8
store i8*%f,i8**%b,align 8
%g=getelementptr inbounds i8,i8*%a,i64 8
%h=bitcast i8*%g to i8**
%i=load i8*,i8**%h,align 8
store i8*%i,i8**%c,align 8
%j=call i8*@sml_alloc(i32 inreg 20)#0
%k=getelementptr inbounds i8,i8*%j,i64 -4
%l=bitcast i8*%k to i32*
store i32 1342177296,i32*%l,align 4
store i8*%j,i8**%d,align 8
%m=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%n=bitcast i8*%j to i8**
store i8*%m,i8**%n,align 8
%o=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%p=getelementptr inbounds i8,i8*%j,i64 8
%q=bitcast i8*%p to i8**
store i8*%o,i8**%q,align 8
%r=getelementptr inbounds i8,i8*%j,i64 16
%s=bitcast i8*%r to i32*
store i32 3,i32*%s,align 4
%t=call i8*@sml_alloc(i32 inreg 28)#0
%u=getelementptr inbounds i8,i8*%t,i64 -4
%v=bitcast i8*%u to i32*
store i32 1342177304,i32*%v,align 4
%w=load i8*,i8**%d,align 8
%x=bitcast i8*%t to i8**
store i8*%w,i8**%x,align 8
%y=getelementptr inbounds i8,i8*%t,i64 8
%z=bitcast i8*%y to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_60 to void(...)*),void(...)**%z,align 8
%A=getelementptr inbounds i8,i8*%t,i64 16
%B=bitcast i8*%A to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN16ElaborateForeach12elaborateExpE_60 to void(...)*),void(...)**%B,align 8
%C=getelementptr inbounds i8,i8*%t,i64 24
%D=bitcast i8*%C to i32*
store i32 -2147483647,i32*%D,align 4
ret i8*%t
}
define internal fastcc i8*@_SMLLLN16ElaborateForeach12elaborateExpE_63(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN16ElaborateForeach12elaborateExpE(i8*inreg%b)
ret i8*%c
}
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
attributes#4={nounwind uwtable}
