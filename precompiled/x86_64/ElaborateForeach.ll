@sml_check_flag=external local_unnamed_addr global i32
@_SMLZ5Match=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[13x i8]}><{[4x i8]zeroinitializer,i32 -2147483635,[13x i8]c"ForeachArray\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[13x i8]}>,<{[4x i8],i32,[13x i8]}>*@a,i32 0,i32 0,i32 0),i32 8),i8*null,i32 3}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[13x i8]}>,<{[4x i8],i32,[13x i8]}>*@a,i32 0,i32 0,i32 0),i32 8),i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@b,i32 0,i32 0,i32 0),i32 8),i32 3}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,[12x i8]}><{[4x i8]zeroinitializer,i32 -2147483636,[12x i8]c"ForeachData\00"}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[12x i8]}>,<{[4x i8],i32,[12x i8]}>*@d,i32 0,i32 0,i32 0),i32 8),i8*null,i32 3}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[12x i8]}>,<{[4x i8],i32,[12x i8]}>*@d,i32 0,i32 0,i32 0),i32 8),i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@e,i32 0,i32 0,i32 0),i32 8),i32 3}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLLN16ElaborateForeach15Fun__FoeachArrayE_60 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach15Fun__FoeachArrayE_91 to void(...)*),i32 -2147483647}>,align 8
@h=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLLN16ElaborateForeach15Fun__ForeachDataE_66 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach15Fun__ForeachDataE_93 to void(...)*),i32 -2147483647}>,align 8
@i=private unnamed_addr constant<{[4x i8],i32,[74x i8]}><{[4x i8]zeroinitializer,i32 -2147483574,[74x i8]c"src/compiler/compilePhases/elaborate/main/ElaborateForeach.sml:51.6(1201)\00"}>,align 8
@j=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN16ElaborateForeach12elaborateExpE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach12elaborateExpE_95 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN16ElaborateForeach12elaborateExpE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@j,i64 0,i32 2)to i8*)
@_SML_ftabab01f826503d0cc7_ElaborateForeach=external global i8
@k=private unnamed_addr global i8 0
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
declare void@_SML_main44ca35c4c731682b_Symbol()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main60e750412e2bb4fe_RecordLabel()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load03d87556ec7f64b2_List(i8*)local_unnamed_addr
declare void@_SML_load44ca35c4c731682b_Symbol(i8*)local_unnamed_addr
declare void@_SML_load60e750412e2bb4fe_RecordLabel(i8*)local_unnamed_addr
define private void@_SML_tabbab01f826503d0cc7_ElaborateForeach()#3{
unreachable
}
define void@_SML_loadab01f826503d0cc7_ElaborateForeach(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@k,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@k,align 1
tail call void@_SML_load03d87556ec7f64b2_List(i8*%a)#0
tail call void@_SML_load44ca35c4c731682b_Symbol(i8*%a)#0
tail call void@_SML_load60e750412e2bb4fe_RecordLabel(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbab01f826503d0cc7_ElaborateForeach,i8*@_SML_ftabab01f826503d0cc7_ElaborateForeach,i8*null)#0
ret void
}
define void@_SML_mainab01f826503d0cc7_ElaborateForeach()local_unnamed_addr#2 gc"smlsharp"{
%a=load i8,i8*@k,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@k,align 1
tail call void@_SML_main03d87556ec7f64b2_List()#2
tail call void@_SML_main44ca35c4c731682b_Symbol()#2
tail call void@_SML_main60e750412e2bb4fe_RecordLabel()#2
br label%d
}
define internal fastcc i8*@_SMLLN16ElaborateForeach9PatRecordE_49(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
define internal fastcc i8*@_SMLLN16ElaborateForeach9PatRecordE_50(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach9PatRecordE_49 to void(...)*),void(...)**%D,align 8
%E=getelementptr inbounds i8,i8*%x,i64 16
%F=bitcast i8*%E to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach9PatRecordE_49 to void(...)*),void(...)**%F,align 8
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
define internal fastcc i8*@_SMLLN16ElaborateForeach9PatRecordE_51(i8*inreg%a)unnamed_addr#4 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
%d=call i8*@sml_alloc(i32 inreg 12)#0
%e=getelementptr inbounds i8,i8*%d,i64 -4
%f=bitcast i8*%e to i32*
store i32 1342177288,i32*%f,align 4
store i8*%d,i8**%c,align 8
%g=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%h=bitcast i8*%d to i8**
store i8*%g,i8**%h,align 8
%i=getelementptr inbounds i8,i8*%d,i64 8
%j=bitcast i8*%i to i32*
store i32 1,i32*%j,align 4
%k=call i8*@sml_alloc(i32 inreg 28)#0
%l=getelementptr inbounds i8,i8*%k,i64 -4
%m=bitcast i8*%l to i32*
store i32 1342177304,i32*%m,align 4
%n=load i8*,i8**%c,align 8
%o=bitcast i8*%k to i8**
store i8*%n,i8**%o,align 8
%p=getelementptr inbounds i8,i8*%k,i64 8
%q=bitcast i8*%p to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach9PatRecordE_50 to void(...)*),void(...)**%q,align 8
%r=getelementptr inbounds i8,i8*%k,i64 16
%s=bitcast i8*%r to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach9PatRecordE_50 to void(...)*),void(...)**%s,align 8
%t=getelementptr inbounds i8,i8*%k,i64 24
%u=bitcast i8*%t to i32*
store i32 -2147483647,i32*%u,align 4
ret i8*%k
}
define internal fastcc i8*@_SMLLN16ElaborateForeach2FnE_53(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
%k=bitcast i8*%a to i8***
br label%p
l:
call void@sml_check(i32 inreg%h)
%m=load i8*,i8**%c,align 8
%n=bitcast i8**%f to i8****
%o=load i8***,i8****%n,align 8
br label%p
p:
%q=phi i8***[%o,%l],[%k,%j]
%r=phi i8*[%m,%l],[%b,%j]
%s=load i8**,i8***%q,align 8
%t=load i8*,i8**%s,align 8
%u=getelementptr inbounds i8,i8*%t,i64 16
%v=bitcast i8*%u to i8*(i8*,i8*)**
%w=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%v,align 8
%x=bitcast i8*%t to i8**
%y=load i8*,i8**%x,align 8
%z=call fastcc i8*%w(i8*inreg%y,i8*inreg%r)
store i8*%z,i8**%d,align 8
%A=call i8*@sml_alloc(i32 inreg 20)#0
%B=getelementptr inbounds i8,i8*%A,i64 -4
%C=bitcast i8*%B to i32*
store i32 1342177296,i32*%C,align 4
%D=load i8*,i8**%d,align 8
%E=bitcast i8*%A to i8**
store i8*%D,i8**%E,align 8
%F=getelementptr inbounds i8,i8*%A,i64 8
%G=bitcast i8*%F to i8**
store i8*null,i8**%G,align 8
%H=getelementptr inbounds i8,i8*%A,i64 16
%I=bitcast i8*%H to i32*
store i32 3,i32*%I,align 4
store i8*null,i8**%e,align 8
%J=call i8*@sml_alloc(i32 inreg 20)#0
%K=getelementptr inbounds i8,i8*%J,i64 -4
%L=bitcast i8*%K to i32*
store i32 1342177296,i32*%L,align 4
store i8*%J,i8**%g,align 8
%M=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%N=bitcast i8*%J to i8**
store i8*%M,i8**%N,align 8
%O=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%P=getelementptr inbounds i8,i8*%J,i64 8
%Q=bitcast i8*%P to i8**
store i8*%O,i8**%Q,align 8
%R=getelementptr inbounds i8,i8*%J,i64 16
%S=bitcast i8*%R to i32*
store i32 3,i32*%S,align 4
%T=bitcast i8**%f to i8***
%U=load i8**,i8***%T,align 8
store i8*null,i8**%f,align 8
%V=load i8*,i8**%U,align 8
%W=getelementptr inbounds i8,i8*%V,i64 8
%X=bitcast i8*%W to i8**
%Y=load i8*,i8**%X,align 8
%Z=getelementptr inbounds i8,i8*%Y,i64 16
%aa=bitcast i8*%Z to i8*(i8*,i8*)**
%ab=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aa,align 8
%ac=bitcast i8*%Y to i8**
%ad=load i8*,i8**%ac,align 8
%ae=load i8*,i8**%c,align 8
%af=call fastcc i8*%ab(i8*inreg%ad,i8*inreg%ae)
store i8*%af,i8**%d,align 8
%ag=call i8*@sml_alloc(i32 inreg 28)#0
%ah=getelementptr inbounds i8,i8*%ag,i64 -4
%ai=bitcast i8*%ah to i32*
store i32 1342177304,i32*%ai,align 4
store i8*%ag,i8**%e,align 8
%aj=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%ak=bitcast i8*%ag to i8**
store i8*%aj,i8**%ak,align 8
%al=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%am=getelementptr inbounds i8,i8*%ag,i64 8
%an=bitcast i8*%am to i8**
store i8*%al,i8**%an,align 8
%ao=load i8*,i8**%c,align 8
%ap=getelementptr inbounds i8,i8*%ag,i64 16
%aq=bitcast i8*%ap to i8**
store i8*%ao,i8**%aq,align 8
%ar=getelementptr inbounds i8,i8*%ag,i64 24
%as=bitcast i8*%ar to i32*
store i32 7,i32*%as,align 4
%at=call i8*@sml_alloc(i32 inreg 20)#0
%au=getelementptr inbounds i8,i8*%at,i64 -4
%av=bitcast i8*%au to i32*
store i32 1342177296,i32*%av,align 4
%aw=load i8*,i8**%e,align 8
%ax=bitcast i8*%at to i8**
store i8*%aw,i8**%ax,align 8
%ay=getelementptr inbounds i8,i8*%at,i64 8
%az=bitcast i8*%ay to i8**
store i8*null,i8**%az,align 8
%aA=getelementptr inbounds i8,i8*%at,i64 16
%aB=bitcast i8*%aA to i32*
store i32 3,i32*%aB,align 4
store i8*%aw,i8**%d,align 8
store i8*null,i8**%e,align 8
%aC=call i8*@sml_alloc(i32 inreg 20)#0
%aD=getelementptr inbounds i8,i8*%aC,i64 -4
%aE=bitcast i8*%aD to i32*
store i32 1342177296,i32*%aE,align 4
store i8*%aC,i8**%f,align 8
%aF=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%aG=bitcast i8*%aC to i8**
store i8*%aF,i8**%aG,align 8
%aH=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aI=getelementptr inbounds i8,i8*%aC,i64 8
%aJ=bitcast i8*%aI to i8**
store i8*%aH,i8**%aJ,align 8
%aK=getelementptr inbounds i8,i8*%aC,i64 16
%aL=bitcast i8*%aK to i32*
store i32 3,i32*%aL,align 4
%aM=call i8*@sml_alloc(i32 inreg 20)#0
%aN=getelementptr inbounds i8,i8*%aM,i64 -4
%aO=bitcast i8*%aN to i32*
store i32 1342177296,i32*%aO,align 4
store i8*%aM,i8**%d,align 8
%aP=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aQ=bitcast i8*%aM to i8**
store i8*%aP,i8**%aQ,align 8
%aR=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aS=getelementptr inbounds i8,i8*%aM,i64 8
%aT=bitcast i8*%aS to i8**
store i8*%aR,i8**%aT,align 8
%aU=getelementptr inbounds i8,i8*%aM,i64 16
%aV=bitcast i8*%aU to i32*
store i32 3,i32*%aV,align 4
%aW=call i8*@sml_alloc(i32 inreg 20)#0
%aX=bitcast i8*%aW to i32*
%aY=getelementptr inbounds i8,i8*%aW,i64 -4
%aZ=bitcast i8*%aY to i32*
store i32 1342177296,i32*%aZ,align 4
%a0=getelementptr inbounds i8,i8*%aW,i64 4
%a1=bitcast i8*%a0 to i32*
store i32 0,i32*%a1,align 1
store i32 10,i32*%aX,align 4
%a2=load i8*,i8**%d,align 8
%a3=getelementptr inbounds i8,i8*%aW,i64 8
%a4=bitcast i8*%a3 to i8**
store i8*%a2,i8**%a4,align 8
%a5=getelementptr inbounds i8,i8*%aW,i64 16
%a6=bitcast i8*%a5 to i32*
store i32 2,i32*%a6,align 4
ret i8*%aW
}
define internal fastcc i8*@_SMLLN16ElaborateForeach2FnE_54(i8*inreg%a)unnamed_addr#4 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
%d=call i8*@sml_alloc(i32 inreg 12)#0
%e=getelementptr inbounds i8,i8*%d,i64 -4
%f=bitcast i8*%e to i32*
store i32 1342177288,i32*%f,align 4
store i8*%d,i8**%c,align 8
%g=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%h=bitcast i8*%d to i8**
store i8*%g,i8**%h,align 8
%i=getelementptr inbounds i8,i8*%d,i64 8
%j=bitcast i8*%i to i32*
store i32 1,i32*%j,align 4
%k=call i8*@sml_alloc(i32 inreg 28)#0
%l=getelementptr inbounds i8,i8*%k,i64 -4
%m=bitcast i8*%l to i32*
store i32 1342177304,i32*%m,align 4
%n=load i8*,i8**%c,align 8
%o=bitcast i8*%k to i8**
store i8*%n,i8**%o,align 8
%p=getelementptr inbounds i8,i8*%k,i64 8
%q=bitcast i8*%p to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach2FnE_53 to void(...)*),void(...)**%q,align 8
%r=getelementptr inbounds i8,i8*%k,i64 16
%s=bitcast i8*%r to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach2FnE_53 to void(...)*),void(...)**%s,align 8
%t=getelementptr inbounds i8,i8*%k,i64 24
%u=bitcast i8*%t to i32*
store i32 -2147483647,i32*%u,align 4
ret i8*%k
}
define internal fastcc i8*@_SMLLN16ElaborateForeach3AppE_56(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
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
br i1%i,label%j,label%l
j:
%k=bitcast i8*%a to i8**
br label%p
l:
call void@sml_check(i32 inreg%h)
%m=load i8*,i8**%c,align 8
%n=bitcast i8**%d to i8***
%o=load i8**,i8***%n,align 8
br label%p
p:
%q=phi i8**[%o,%l],[%k,%j]
%r=phi i8*[%m,%l],[%b,%j]
%s=load i8*,i8**%q,align 8
%t=getelementptr inbounds i8,i8*%s,i64 16
%u=bitcast i8*%t to i8*(i8*,i8*)**
%v=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%u,align 8
%w=bitcast i8*%s to i8**
%x=load i8*,i8**%w,align 8
%y=call fastcc i8*%v(i8*inreg%x,i8*inreg%r)
store i8*%y,i8**%f,align 8
%z=load i8*,i8**%d,align 8
%A=getelementptr inbounds i8,i8*%z,i64 8
%B=bitcast i8*%A to i8**
%C=load i8*,i8**%B,align 8
%D=getelementptr inbounds i8,i8*%C,i64 16
%E=bitcast i8*%D to i8*(i8*,i8*)**
%F=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%E,align 8
store i8*null,i8**%d,align 8
%G=bitcast i8*%C to i8**
%H=load i8*,i8**%G,align 8
%I=load i8*,i8**%c,align 8
%J=call fastcc i8*%F(i8*inreg%H,i8*inreg%I)
store i8*%J,i8**%d,align 8
%K=call i8*@sml_alloc(i32 inreg 20)#0
%L=getelementptr inbounds i8,i8*%K,i64 -4
%M=bitcast i8*%L to i32*
store i32 1342177296,i32*%M,align 4
%N=load i8*,i8**%d,align 8
%O=bitcast i8*%K to i8**
store i8*%N,i8**%O,align 8
%P=getelementptr inbounds i8,i8*%K,i64 8
%Q=bitcast i8*%P to i8**
store i8*null,i8**%Q,align 8
%R=getelementptr inbounds i8,i8*%K,i64 16
%S=bitcast i8*%R to i32*
store i32 3,i32*%S,align 4
store i8*null,i8**%e,align 8
%T=call i8*@sml_alloc(i32 inreg 20)#0
%U=getelementptr inbounds i8,i8*%T,i64 -4
%V=bitcast i8*%U to i32*
store i32 1342177296,i32*%V,align 4
store i8*%T,i8**%g,align 8
%W=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%X=bitcast i8*%T to i8**
store i8*%W,i8**%X,align 8
%Y=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%Z=getelementptr inbounds i8,i8*%T,i64 8
%aa=bitcast i8*%Z to i8**
store i8*%Y,i8**%aa,align 8
%ab=getelementptr inbounds i8,i8*%T,i64 16
%ac=bitcast i8*%ab to i32*
store i32 3,i32*%ac,align 4
%ad=call i8*@sml_alloc(i32 inreg 28)#0
%ae=getelementptr inbounds i8,i8*%ad,i64 -4
%af=bitcast i8*%ae to i32*
store i32 1342177304,i32*%af,align 4
store i8*%ad,i8**%d,align 8
%ag=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ah=bitcast i8*%ad to i8**
store i8*%ag,i8**%ah,align 8
%ai=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aj=getelementptr inbounds i8,i8*%ad,i64 8
%ak=bitcast i8*%aj to i8**
store i8*%ai,i8**%ak,align 8
%al=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%am=getelementptr inbounds i8,i8*%ad,i64 16
%an=bitcast i8*%am to i8**
store i8*%al,i8**%an,align 8
%ao=getelementptr inbounds i8,i8*%ad,i64 24
%ap=bitcast i8*%ao to i32*
store i32 7,i32*%ap,align 4
%aq=call i8*@sml_alloc(i32 inreg 20)#0
%ar=getelementptr inbounds i8,i8*%aq,i64 -4
%as=bitcast i8*%ar to i32*
store i32 1342177296,i32*%as,align 4
%at=bitcast i8*%aq to i64*
store i64 0,i64*%at,align 4
%au=load i8*,i8**%d,align 8
%av=getelementptr inbounds i8,i8*%aq,i64 8
%aw=bitcast i8*%av to i8**
store i8*%au,i8**%aw,align 8
%ax=getelementptr inbounds i8,i8*%aq,i64 16
%ay=bitcast i8*%ax to i32*
store i32 2,i32*%ay,align 4
ret i8*%aq
}
define internal fastcc i8*@_SMLLN16ElaborateForeach3AppE_57(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
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
%k=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%l=bitcast i8*%h to i8**
store i8*%k,i8**%l,align 8
%m=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%n=getelementptr inbounds i8,i8*%h,i64 8
%o=bitcast i8*%n to i8**
store i8*%m,i8**%o,align 8
%p=getelementptr inbounds i8,i8*%h,i64 16
%q=bitcast i8*%p to i32*
store i32 3,i32*%q,align 4
%r=call i8*@sml_alloc(i32 inreg 28)#0
%s=getelementptr inbounds i8,i8*%r,i64 -4
%t=bitcast i8*%s to i32*
store i32 1342177304,i32*%t,align 4
%u=load i8*,i8**%e,align 8
%v=bitcast i8*%r to i8**
store i8*%u,i8**%v,align 8
%w=getelementptr inbounds i8,i8*%r,i64 8
%x=bitcast i8*%w to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach3AppE_56 to void(...)*),void(...)**%x,align 8
%y=getelementptr inbounds i8,i8*%r,i64 16
%z=bitcast i8*%y to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach3AppE_56 to void(...)*),void(...)**%z,align 8
%A=getelementptr inbounds i8,i8*%r,i64 24
%B=bitcast i8*%A to i32*
store i32 -2147483647,i32*%B,align 4
ret i8*%r
}
define internal fastcc i8*@_SMLLN16ElaborateForeach3AppE_58(i8*inreg%a)unnamed_addr#4 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
%d=call i8*@sml_alloc(i32 inreg 12)#0
%e=getelementptr inbounds i8,i8*%d,i64 -4
%f=bitcast i8*%e to i32*
store i32 1342177288,i32*%f,align 4
store i8*%d,i8**%c,align 8
%g=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%h=bitcast i8*%d to i8**
store i8*%g,i8**%h,align 8
%i=getelementptr inbounds i8,i8*%d,i64 8
%j=bitcast i8*%i to i32*
store i32 1,i32*%j,align 4
%k=call i8*@sml_alloc(i32 inreg 28)#0
%l=getelementptr inbounds i8,i8*%k,i64 -4
%m=bitcast i8*%l to i32*
store i32 1342177304,i32*%m,align 4
%n=load i8*,i8**%c,align 8
%o=bitcast i8*%k to i8**
store i8*%n,i8**%o,align 8
%p=getelementptr inbounds i8,i8*%k,i64 8
%q=bitcast i8*%p to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach3AppE_57 to void(...)*),void(...)**%q,align 8
%r=getelementptr inbounds i8,i8*%k,i64 16
%s=bitcast i8*%r to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach3AppE_57 to void(...)*),void(...)**%s,align 8
%t=getelementptr inbounds i8,i8*%k,i64 24
%u=bitcast i8*%t to i32*
store i32 -2147483647,i32*%u,align 4
ret i8*%k
}
define internal fastcc i8*@_SMLLN16ElaborateForeach15Fun__FoeachArrayE_60(i8*inreg%a)#2 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
store i8*%a,i8**%b,align 8
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=call fastcc i8*@_SMLFN6Symbol12mkLongsymbolE(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@c,i64 0,i32 2)to i8*))
%h=getelementptr inbounds i8,i8*%g,i64 16
%i=bitcast i8*%h to i8*(i8*,i8*)**
%j=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%i,align 8
%k=bitcast i8*%g to i8**
%l=load i8*,i8**%k,align 8
%m=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%n=call fastcc i8*%j(i8*inreg%l,i8*inreg%m)
store i8*%n,i8**%b,align 8
%o=call i8*@sml_alloc(i32 inreg 20)#0
%p=bitcast i8*%o to i32*
%q=getelementptr inbounds i8,i8*%o,i64 -4
%r=bitcast i8*%q to i32*
store i32 1342177296,i32*%r,align 4
%s=getelementptr inbounds i8,i8*%o,i64 4
%t=bitcast i8*%s to i32*
store i32 0,i32*%t,align 1
store i32 25,i32*%p,align 4
%u=load i8*,i8**%b,align 8
%v=getelementptr inbounds i8,i8*%o,i64 8
%w=bitcast i8*%v to i8**
store i8*%u,i8**%w,align 8
%x=getelementptr inbounds i8,i8*%o,i64 16
%y=bitcast i8*%x to i32*
store i32 2,i32*%y,align 4
ret i8*%o
}
define internal fastcc i8*@_SMLLN16ElaborateForeach15Fun__FoeachArrayE_62(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%h,label%g
g:
call void@sml_check(i32 inreg%e)
br label%h
h:
%i=call fastcc i8*@_SMLLN16ElaborateForeach3AppE_58(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@g,i64 0,i32 2)to i8*))
%j=getelementptr inbounds i8,i8*%i,i64 16
%k=bitcast i8*%j to i8*(i8*,i8*)**
%l=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%k,align 8
%m=bitcast i8*%i to i8**
%n=load i8*,i8**%m,align 8
%o=bitcast i8**%d to i8***
%p=load i8**,i8***%o,align 8
%q=load i8*,i8**%p,align 8
%r=call fastcc i8*%l(i8*inreg%n,i8*inreg%q)
%s=call fastcc i8*@_SMLLN16ElaborateForeach3AppE_58(i8*inreg%r)
%t=getelementptr inbounds i8,i8*%s,i64 16
%u=bitcast i8*%t to i8*(i8*,i8*)**
%v=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%u,align 8
%w=bitcast i8*%s to i8**
%x=load i8*,i8**%w,align 8
%y=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%z=getelementptr inbounds i8,i8*%y,i64 8
%A=bitcast i8*%z to i8**
%B=load i8*,i8**%A,align 8
%C=call fastcc i8*%v(i8*inreg%x,i8*inreg%B)
%D=call fastcc i8*@_SMLLN16ElaborateForeach3AppE_58(i8*inreg%C)
%E=getelementptr inbounds i8,i8*%D,i64 16
%F=bitcast i8*%E to i8*(i8*,i8*)**
%G=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%F,align 8
%H=bitcast i8*%D to i8**
%I=load i8*,i8**%H,align 8
%J=load i8*,i8**%c,align 8
%K=tail call fastcc i8*%G(i8*inreg%I,i8*inreg%J)
ret i8*%K
}
define internal fastcc i8*@_SMLLN16ElaborateForeach15Fun__FoeachArrayE_63(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
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
%k=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%l=bitcast i8*%h to i8**
store i8*%k,i8**%l,align 8
%m=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%n=getelementptr inbounds i8,i8*%h,i64 8
%o=bitcast i8*%n to i8**
store i8*%m,i8**%o,align 8
%p=getelementptr inbounds i8,i8*%h,i64 16
%q=bitcast i8*%p to i32*
store i32 3,i32*%q,align 4
%r=call i8*@sml_alloc(i32 inreg 28)#0
%s=getelementptr inbounds i8,i8*%r,i64 -4
%t=bitcast i8*%s to i32*
store i32 1342177304,i32*%t,align 4
%u=load i8*,i8**%e,align 8
%v=bitcast i8*%r to i8**
store i8*%u,i8**%v,align 8
%w=getelementptr inbounds i8,i8*%r,i64 8
%x=bitcast i8*%w to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach15Fun__FoeachArrayE_62 to void(...)*),void(...)**%x,align 8
%y=getelementptr inbounds i8,i8*%r,i64 16
%z=bitcast i8*%y to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach15Fun__FoeachArrayE_62 to void(...)*),void(...)**%z,align 8
%A=getelementptr inbounds i8,i8*%r,i64 24
%B=bitcast i8*%A to i32*
store i32 -2147483647,i32*%B,align 4
ret i8*%r
}
define internal fastcc i8*@_SMLLN16ElaborateForeach15Fun__ForeachDataE_66(i8*inreg%a)#2 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
store i8*%a,i8**%b,align 8
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=call fastcc i8*@_SMLFN6Symbol12mkLongsymbolE(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@f,i64 0,i32 2)to i8*))
%h=getelementptr inbounds i8,i8*%g,i64 16
%i=bitcast i8*%h to i8*(i8*,i8*)**
%j=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%i,align 8
%k=bitcast i8*%g to i8**
%l=load i8*,i8**%k,align 8
%m=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%n=call fastcc i8*%j(i8*inreg%l,i8*inreg%m)
store i8*%n,i8**%b,align 8
%o=call i8*@sml_alloc(i32 inreg 20)#0
%p=bitcast i8*%o to i32*
%q=getelementptr inbounds i8,i8*%o,i64 -4
%r=bitcast i8*%q to i32*
store i32 1342177296,i32*%r,align 4
%s=getelementptr inbounds i8,i8*%o,i64 4
%t=bitcast i8*%s to i32*
store i32 0,i32*%t,align 1
store i32 25,i32*%p,align 4
%u=load i8*,i8**%b,align 8
%v=getelementptr inbounds i8,i8*%o,i64 8
%w=bitcast i8*%v to i8**
store i8*%u,i8**%w,align 8
%x=getelementptr inbounds i8,i8*%o,i64 16
%y=bitcast i8*%x to i32*
store i32 2,i32*%y,align 4
ret i8*%o
}
define internal fastcc i8*@_SMLLN16ElaborateForeach15Fun__ForeachDataE_68(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%h,label%g
g:
call void@sml_check(i32 inreg%e)
br label%h
h:
%i=call fastcc i8*@_SMLLN16ElaborateForeach3AppE_58(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@h,i64 0,i32 2)to i8*))
%j=getelementptr inbounds i8,i8*%i,i64 16
%k=bitcast i8*%j to i8*(i8*,i8*)**
%l=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%k,align 8
%m=bitcast i8*%i to i8**
%n=load i8*,i8**%m,align 8
%o=bitcast i8**%d to i8***
%p=load i8**,i8***%o,align 8
%q=load i8*,i8**%p,align 8
%r=call fastcc i8*%l(i8*inreg%n,i8*inreg%q)
%s=call fastcc i8*@_SMLLN16ElaborateForeach3AppE_58(i8*inreg%r)
%t=getelementptr inbounds i8,i8*%s,i64 16
%u=bitcast i8*%t to i8*(i8*,i8*)**
%v=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%u,align 8
%w=bitcast i8*%s to i8**
%x=load i8*,i8**%w,align 8
%y=load i8*,i8**%d,align 8
%z=getelementptr inbounds i8,i8*%y,i64 8
%A=bitcast i8*%z to i8**
%B=load i8*,i8**%A,align 8
%C=call fastcc i8*%v(i8*inreg%x,i8*inreg%B)
%D=call fastcc i8*@_SMLLN16ElaborateForeach3AppE_58(i8*inreg%C)
%E=getelementptr inbounds i8,i8*%D,i64 16
%F=bitcast i8*%E to i8*(i8*,i8*)**
%G=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%F,align 8
%H=bitcast i8*%D to i8**
%I=load i8*,i8**%H,align 8
%J=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%K=getelementptr inbounds i8,i8*%J,i64 16
%L=bitcast i8*%K to i8**
%M=load i8*,i8**%L,align 8
%N=call fastcc i8*%G(i8*inreg%I,i8*inreg%M)
%O=call fastcc i8*@_SMLLN16ElaborateForeach3AppE_58(i8*inreg%N)
%P=getelementptr inbounds i8,i8*%O,i64 16
%Q=bitcast i8*%P to i8*(i8*,i8*)**
%R=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%Q,align 8
%S=bitcast i8*%O to i8**
%T=load i8*,i8**%S,align 8
%U=load i8*,i8**%c,align 8
%V=tail call fastcc i8*%R(i8*inreg%T,i8*inreg%U)
ret i8*%V
}
define internal fastcc i8*@_SMLLN16ElaborateForeach15Fun__ForeachDataE_69(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
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
%l=call i8*@sml_alloc(i32 inreg 28)#0
%m=getelementptr inbounds i8,i8*%l,i64 -4
%n=bitcast i8*%m to i32*
store i32 1342177304,i32*%n,align 4
store i8*%l,i8**%f,align 8
%o=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%p=bitcast i8*%l to i8**
store i8*%o,i8**%p,align 8
%q=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%r=getelementptr inbounds i8,i8*%l,i64 8
%s=bitcast i8*%r to i8**
store i8*%q,i8**%s,align 8
%t=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%u=getelementptr inbounds i8,i8*%l,i64 16
%v=bitcast i8*%u to i8**
store i8*%t,i8**%v,align 8
%w=getelementptr inbounds i8,i8*%l,i64 24
%x=bitcast i8*%w to i32*
store i32 7,i32*%x,align 4
%y=call i8*@sml_alloc(i32 inreg 28)#0
%z=getelementptr inbounds i8,i8*%y,i64 -4
%A=bitcast i8*%z to i32*
store i32 1342177304,i32*%A,align 4
%B=load i8*,i8**%f,align 8
%C=bitcast i8*%y to i8**
store i8*%B,i8**%C,align 8
%D=getelementptr inbounds i8,i8*%y,i64 8
%E=bitcast i8*%D to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach15Fun__ForeachDataE_68 to void(...)*),void(...)**%E,align 8
%F=getelementptr inbounds i8,i8*%y,i64 16
%G=bitcast i8*%F to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach15Fun__ForeachDataE_68 to void(...)*),void(...)**%G,align 8
%H=getelementptr inbounds i8,i8*%y,i64 24
%I=bitcast i8*%H to i32*
store i32 -2147483647,i32*%I,align 4
ret i8*%y
}
define internal fastcc i8*@_SMLLN16ElaborateForeach15Fun__ForeachDataE_70(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
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
%k=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%l=bitcast i8*%h to i8**
store i8*%k,i8**%l,align 8
%m=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%n=getelementptr inbounds i8,i8*%h,i64 8
%o=bitcast i8*%n to i8**
store i8*%m,i8**%o,align 8
%p=getelementptr inbounds i8,i8*%h,i64 16
%q=bitcast i8*%p to i32*
store i32 3,i32*%q,align 4
%r=call i8*@sml_alloc(i32 inreg 28)#0
%s=getelementptr inbounds i8,i8*%r,i64 -4
%t=bitcast i8*%s to i32*
store i32 1342177304,i32*%t,align 4
%u=load i8*,i8**%e,align 8
%v=bitcast i8*%r to i8**
store i8*%u,i8**%v,align 8
%w=getelementptr inbounds i8,i8*%r,i64 8
%x=bitcast i8*%w to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach15Fun__ForeachDataE_69 to void(...)*),void(...)**%x,align 8
%y=getelementptr inbounds i8,i8*%r,i64 16
%z=bitcast i8*%y to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach15Fun__ForeachDataE_69 to void(...)*),void(...)**%z,align 8
%A=getelementptr inbounds i8,i8*%r,i64 24
%B=bitcast i8*%A to i32*
store i32 -2147483647,i32*%B,align 4
ret i8*%r
}
define internal fastcc i8*@_SMLL3pat_73(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%a to i8**
%d=load i8*,i8**%c,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLL5idPat_74(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
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
define internal fastcc i8*@_SMLL4data_75(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%a to i8**
%d=load i8*,i8**%c,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLL8iterator_76(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%a to i8**
%d=load i8*,i8**%c,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLL4pred_77(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%a to i8**
%d=load i8*,i8**%c,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLL3pat_78(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%a to i8**
%d=load i8*,i8**%c,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLL5idPat_79(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
%e=bitcast i8*%a to i8**
%f=load i8*,i8**%e,align 8
%g=getelementptr inbounds i8,i8*%f,i64 8
%h=bitcast i8*%g to i8**
%i=load i8*,i8**%h,align 8
store i8*%i,i8**%c,align 8
%j=call i8*@sml_alloc(i32 inreg 20)#0
%k=getelementptr inbounds i8,i8*%j,i64 -4
%l=bitcast i8*%k to i32*
store i32 1342177296,i32*%l,align 4
store i8*%j,i8**%d,align 8
%m=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%n=bitcast i8*%j to i8**
store i8*%m,i8**%n,align 8
%o=getelementptr inbounds i8,i8*%j,i64 8
%p=bitcast i8*%o to i8**
store i8*null,i8**%p,align 8
%q=getelementptr inbounds i8,i8*%j,i64 16
%r=bitcast i8*%q to i32*
store i32 3,i32*%r,align 4
%s=call i8*@sml_alloc(i32 inreg 20)#0
%t=bitcast i8*%s to i32*
%u=getelementptr inbounds i8,i8*%s,i64 -4
%v=bitcast i8*%u to i32*
store i32 1342177296,i32*%v,align 4
%w=getelementptr inbounds i8,i8*%s,i64 4
%x=bitcast i8*%w to i32*
store i32 0,i32*%x,align 1
store i32 2,i32*%t,align 4
%y=load i8*,i8**%d,align 8
%z=getelementptr inbounds i8,i8*%s,i64 8
%A=bitcast i8*%z to i8**
store i8*%y,i8**%A,align 8
%B=getelementptr inbounds i8,i8*%s,i64 16
%C=bitcast i8*%B to i32*
store i32 2,i32*%C,align 4
ret i8*%s
}
define internal fastcc i8*@_SMLL4data_80(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%a to i8**
%d=load i8*,i8**%c,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLL10whereParam_81(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%a to i8**
%d=load i8*,i8**%c,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLL8iterator_82(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%a to i8**
%d=load i8*,i8**%c,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLL4pred_83(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%a to i8**
%d=load i8*,i8**%c,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLLN16ElaborateForeach12elaborateExpE_85(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
u:
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
%n=alloca i8*,align 8
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
call void@llvm.gcroot(i8**%k,i8*null)#0
call void@llvm.gcroot(i8**%l,i8*null)#0
call void@llvm.gcroot(i8**%m,i8*null)#0
call void@llvm.gcroot(i8**%n,i8*null)#0
store i8*%a,i8**%k,align 8
store i8*%b,i8**%g,align 8
%o=load atomic i32,i32*@sml_check_flag unordered,align 4
%p=icmp eq i32%o,0
br i1%p,label%s,label%q
q:
call void@sml_check(i32 inreg%o)
%r=load i8*,i8**%g,align 8
br label%s
s:
%t=phi i8*[%r,%q],[%b,%u]
store i8*%t,i8**%i,align 8
%v=bitcast i8*%t to i8**
%w=load i8*,i8**%v,align 8
%x=bitcast i8*%w to i32*
%y=load i32,i32*%x,align 4
switch i32%y,label%z[
i32 0,label%et
i32 1,label%R
]
z:
store i8*null,i8**%i,align 8
store i8*null,i8**%k,align 8
call void@sml_matchcomp_bug()
%A=load i8*,i8**@_SMLZ5Match,align 8
store i8*%A,i8**%g,align 8
%B=call i8*@sml_alloc(i32 inreg 20)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177296,i32*%D,align 4
store i8*%B,i8**%h,align 8
%E=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%F=bitcast i8*%B to i8**
store i8*%E,i8**%F,align 8
%G=getelementptr inbounds i8,i8*%B,i64 8
%H=bitcast i8*%G to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[74x i8]}>,<{[4x i8],i32,[74x i8]}>*@i,i64 0,i32 2,i64 0),i8**%H,align 8
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
%P=load i8*,i8**%h,align 8
%Q=bitcast i8*%K to i8**
store i8*%P,i8**%Q,align 8
call void@sml_raise(i8*inreg%K)#1
unreachable
R:
%S=getelementptr inbounds i8,i8*%w,i64 8
%T=bitcast i8*%S to i8**
%U=load i8*,i8**%T,align 8
store i8*%U,i8**%j,align 8
%V=bitcast i8**%k to i8***
%W=load i8**,i8***%V,align 8
%X=load i8*,i8**%W,align 8
%Y=getelementptr inbounds i8,i8*%X,i64 8
%Z=bitcast i8*%Y to i8**
%aa=load i8*,i8**%Z,align 8
%ab=getelementptr inbounds i8,i8*%aa,i64 16
%ac=bitcast i8*%ab to i8*(i8*,i8*)**
%ad=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ac,align 8
%ae=bitcast i8*%aa to i8**
%af=load i8*,i8**%ae,align 8
%ag=getelementptr inbounds i8,i8*%U,i64 24
%ah=bitcast i8*%ag to i8**
%ai=load i8*,i8**%ah,align 8
%aj=call fastcc i8*%ad(i8*inreg%af,i8*inreg%ai)
store i8*%aj,i8**%g,align 8
%ak=call i8*@sml_alloc(i32 inreg 12)#0
%al=getelementptr inbounds i8,i8*%ak,i64 -4
%am=bitcast i8*%al to i32*
store i32 1342177288,i32*%am,align 4
store i8*%ak,i8**%h,align 8
%an=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%ao=bitcast i8*%ak to i8**
store i8*%an,i8**%ao,align 8
%ap=getelementptr inbounds i8,i8*%ak,i64 8
%aq=bitcast i8*%ap to i32*
store i32 1,i32*%aq,align 4
%ar=call i8*@sml_alloc(i32 inreg 28)#0
%as=getelementptr inbounds i8,i8*%ar,i64 -4
%at=bitcast i8*%as to i32*
store i32 1342177304,i32*%at,align 4
store i8*%ar,i8**%g,align 8
%au=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%av=bitcast i8*%ar to i8**
store i8*%au,i8**%av,align 8
%aw=getelementptr inbounds i8,i8*%ar,i64 8
%ax=bitcast i8*%aw to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL3pat_78 to void(...)*),void(...)**%ax,align 8
%ay=getelementptr inbounds i8,i8*%ar,i64 16
%az=bitcast i8*%ay to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL3pat_78 to void(...)*),void(...)**%az,align 8
%aA=getelementptr inbounds i8,i8*%ar,i64 24
%aB=bitcast i8*%aA to i32*
store i32 -2147483647,i32*%aB,align 4
%aC=call i8*@sml_alloc(i32 inreg 12)#0
%aD=getelementptr inbounds i8,i8*%aC,i64 -4
%aE=bitcast i8*%aD to i32*
store i32 1342177288,i32*%aE,align 4
store i8*%aC,i8**%h,align 8
%aF=load i8*,i8**%j,align 8
%aG=bitcast i8*%aC to i8**
store i8*%aF,i8**%aG,align 8
%aH=getelementptr inbounds i8,i8*%aC,i64 8
%aI=bitcast i8*%aH to i32*
store i32 1,i32*%aI,align 4
%aJ=call i8*@sml_alloc(i32 inreg 28)#0
%aK=getelementptr inbounds i8,i8*%aJ,i64 -4
%aL=bitcast i8*%aK to i32*
store i32 1342177304,i32*%aL,align 4
store i8*%aJ,i8**%l,align 8
%aM=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%aN=bitcast i8*%aJ to i8**
store i8*%aM,i8**%aN,align 8
%aO=getelementptr inbounds i8,i8*%aJ,i64 8
%aP=bitcast i8*%aO to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL5idPat_79 to void(...)*),void(...)**%aP,align 8
%aQ=getelementptr inbounds i8,i8*%aJ,i64 16
%aR=bitcast i8*%aQ to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL5idPat_79 to void(...)*),void(...)**%aR,align 8
%aS=getelementptr inbounds i8,i8*%aJ,i64 24
%aT=bitcast i8*%aS to i32*
store i32 -2147483647,i32*%aT,align 4
%aU=call i8*@sml_alloc(i32 inreg 20)#0
%aV=getelementptr inbounds i8,i8*%aU,i64 -4
%aW=bitcast i8*%aV to i32*
store i32 1342177296,i32*%aW,align 4
store i8*%aU,i8**%h,align 8
%aX=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%aY=bitcast i8*%aU to i8**
store i8*%aX,i8**%aY,align 8
%aZ=getelementptr inbounds i8,i8*%aU,i64 8
%a0=bitcast i8*%aZ to i8**
store i8*null,i8**%a0,align 8
%a1=getelementptr inbounds i8,i8*%aU,i64 16
%a2=bitcast i8*%a1 to i32*
store i32 3,i32*%a2,align 4
%a3=call i8*@sml_alloc(i32 inreg 20)#0
%a4=getelementptr inbounds i8,i8*%a3,i64 -4
%a5=bitcast i8*%a4 to i32*
store i32 1342177296,i32*%a5,align 4
store i8*%a3,i8**%g,align 8
%a6=load i8*,i8**%l,align 8
store i8*null,i8**%l,align 8
%a7=bitcast i8*%a3 to i8**
store i8*%a6,i8**%a7,align 8
%a8=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%a9=getelementptr inbounds i8,i8*%a3,i64 8
%ba=bitcast i8*%a9 to i8**
store i8*%a8,i8**%ba,align 8
%bb=getelementptr inbounds i8,i8*%a3,i64 16
%bc=bitcast i8*%bb to i32*
store i32 3,i32*%bc,align 4
%bd=call fastcc i8*@_SMLFN11RecordLabel9tupleListE(i32 inreg 1,i32 inreg 8)
%be=getelementptr inbounds i8,i8*%bd,i64 16
%bf=bitcast i8*%be to i8*(i8*,i8*)**
%bg=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bf,align 8
%bh=bitcast i8*%bd to i8**
%bi=load i8*,i8**%bh,align 8
%bj=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%bk=call fastcc i8*%bg(i8*inreg%bi,i8*inreg%bj)
%bl=call fastcc i8*@_SMLLN16ElaborateForeach9PatRecordE_51(i8*inreg%bk)
store i8*%bl,i8**%g,align 8
%bm=bitcast i8**%k to i8****
%bn=load i8***,i8****%bm,align 8
%bo=load i8**,i8***%bn,align 8
%bp=load i8*,i8**%bo,align 8
%bq=getelementptr inbounds i8,i8*%bp,i64 16
%br=bitcast i8*%bq to i8*(i8*,i8*)**
%bs=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%br,align 8
%bt=bitcast i8*%bp to i8**
%bu=load i8*,i8**%bt,align 8
%bv=bitcast i8**%j to i8***
%bw=load i8**,i8***%bv,align 8
%bx=load i8*,i8**%bw,align 8
%by=call fastcc i8*%bs(i8*inreg%bu,i8*inreg%bx)
store i8*%by,i8**%h,align 8
%bz=call i8*@sml_alloc(i32 inreg 12)#0
%bA=getelementptr inbounds i8,i8*%bz,i64 -4
%bB=bitcast i8*%bA to i32*
store i32 1342177288,i32*%bB,align 4
store i8*%bz,i8**%l,align 8
%bC=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%bD=bitcast i8*%bz to i8**
store i8*%bC,i8**%bD,align 8
%bE=getelementptr inbounds i8,i8*%bz,i64 8
%bF=bitcast i8*%bE to i32*
store i32 1,i32*%bF,align 4
%bG=call i8*@sml_alloc(i32 inreg 28)#0
%bH=getelementptr inbounds i8,i8*%bG,i64 -4
%bI=bitcast i8*%bH to i32*
store i32 1342177304,i32*%bI,align 4
store i8*%bG,i8**%m,align 8
%bJ=load i8*,i8**%l,align 8
store i8*null,i8**%l,align 8
%bK=bitcast i8*%bG to i8**
store i8*%bJ,i8**%bK,align 8
%bL=getelementptr inbounds i8,i8*%bG,i64 8
%bM=bitcast i8*%bL to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL4data_80 to void(...)*),void(...)**%bM,align 8
%bN=getelementptr inbounds i8,i8*%bG,i64 16
%bO=bitcast i8*%bN to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL4data_80 to void(...)*),void(...)**%bO,align 8
%bP=getelementptr inbounds i8,i8*%bG,i64 24
%bQ=bitcast i8*%bP to i32*
store i32 -2147483647,i32*%bQ,align 4
%bR=load i8***,i8****%bm,align 8
%bS=load i8**,i8***%bR,align 8
%bT=load i8*,i8**%bS,align 8
%bU=getelementptr inbounds i8,i8*%bT,i64 16
%bV=bitcast i8*%bU to i8*(i8*,i8*)**
%bW=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%bV,align 8
%bX=bitcast i8*%bT to i8**
%bY=load i8*,i8**%bX,align 8
%bZ=load i8*,i8**%j,align 8
%b0=getelementptr inbounds i8,i8*%bZ,i64 40
%b1=bitcast i8*%b0 to i8**
%b2=load i8*,i8**%b1,align 8
%b3=call fastcc i8*%bW(i8*inreg%bY,i8*inreg%b2)
store i8*%b3,i8**%h,align 8
%b4=call i8*@sml_alloc(i32 inreg 12)#0
%b5=getelementptr inbounds i8,i8*%b4,i64 -4
%b6=bitcast i8*%b5 to i32*
store i32 1342177288,i32*%b6,align 4
store i8*%b4,i8**%l,align 8
%b7=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%b8=bitcast i8*%b4 to i8**
store i8*%b7,i8**%b8,align 8
%b9=getelementptr inbounds i8,i8*%b4,i64 8
%ca=bitcast i8*%b9 to i32*
store i32 1,i32*%ca,align 4
%cb=call i8*@sml_alloc(i32 inreg 28)#0
%cc=getelementptr inbounds i8,i8*%cb,i64 -4
%cd=bitcast i8*%cc to i32*
store i32 1342177304,i32*%cd,align 4
store i8*%cb,i8**%n,align 8
%ce=load i8*,i8**%l,align 8
store i8*null,i8**%l,align 8
%cf=bitcast i8*%cb to i8**
store i8*%ce,i8**%cf,align 8
%cg=getelementptr inbounds i8,i8*%cb,i64 8
%ch=bitcast i8*%cg to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL10whereParam_81 to void(...)*),void(...)**%ch,align 8
%ci=getelementptr inbounds i8,i8*%cb,i64 16
%cj=bitcast i8*%ci to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL10whereParam_81 to void(...)*),void(...)**%cj,align 8
%ck=getelementptr inbounds i8,i8*%cb,i64 24
%cl=bitcast i8*%ck to i32*
store i32 -2147483647,i32*%cl,align 4
%cm=load i8***,i8****%bm,align 8
%cn=load i8**,i8***%cm,align 8
%co=load i8*,i8**%cn,align 8
%cp=getelementptr inbounds i8,i8*%co,i64 16
%cq=bitcast i8*%cp to i8*(i8*,i8*)**
%cr=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%cq,align 8
%cs=bitcast i8*%co to i8**
%ct=load i8*,i8**%cs,align 8
%cu=load i8*,i8**%j,align 8
%cv=getelementptr inbounds i8,i8*%cu,i64 16
%cw=bitcast i8*%cv to i8**
%cx=load i8*,i8**%cw,align 8
%cy=call fastcc i8*%cr(i8*inreg%ct,i8*inreg%cx)
store i8*%cy,i8**%h,align 8
%cz=call i8*@sml_alloc(i32 inreg 12)#0
%cA=getelementptr inbounds i8,i8*%cz,i64 -4
%cB=bitcast i8*%cA to i32*
store i32 1342177288,i32*%cB,align 4
store i8*%cz,i8**%l,align 8
%cC=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%cD=bitcast i8*%cz to i8**
store i8*%cC,i8**%cD,align 8
%cE=getelementptr inbounds i8,i8*%cz,i64 8
%cF=bitcast i8*%cE to i32*
store i32 1,i32*%cF,align 4
%cG=call i8*@sml_alloc(i32 inreg 28)#0
%cH=getelementptr inbounds i8,i8*%cG,i64 -4
%cI=bitcast i8*%cH to i32*
store i32 1342177304,i32*%cI,align 4
store i8*%cG,i8**%h,align 8
%cJ=load i8*,i8**%l,align 8
store i8*null,i8**%l,align 8
%cK=bitcast i8*%cG to i8**
store i8*%cJ,i8**%cK,align 8
%cL=getelementptr inbounds i8,i8*%cG,i64 8
%cM=bitcast i8*%cL to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL8iterator_82 to void(...)*),void(...)**%cM,align 8
%cN=getelementptr inbounds i8,i8*%cG,i64 16
%cO=bitcast i8*%cN to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL8iterator_82 to void(...)*),void(...)**%cO,align 8
%cP=getelementptr inbounds i8,i8*%cG,i64 24
%cQ=bitcast i8*%cP to i32*
store i32 -2147483647,i32*%cQ,align 4
%cR=call i8*@sml_alloc(i32 inreg 20)#0
%cS=getelementptr inbounds i8,i8*%cR,i64 -4
%cT=bitcast i8*%cS to i32*
store i32 1342177296,i32*%cT,align 4
%cU=load i8*,i8**%g,align 8
%cV=bitcast i8*%cR to i8**
store i8*%cU,i8**%cV,align 8
%cW=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%cX=getelementptr inbounds i8,i8*%cR,i64 8
%cY=bitcast i8*%cX to i8**
store i8*%cW,i8**%cY,align 8
%cZ=getelementptr inbounds i8,i8*%cR,i64 16
%c0=bitcast i8*%cZ to i32*
store i32 3,i32*%c0,align 4
%c1=call fastcc i8*@_SMLLN16ElaborateForeach2FnE_54(i8*inreg%cR)
store i8*%c1,i8**%h,align 8
%c2=load i8***,i8****%bm,align 8
store i8*null,i8**%k,align 8
%c3=load i8**,i8***%c2,align 8
%c4=load i8*,i8**%c3,align 8
%c5=getelementptr inbounds i8,i8*%c4,i64 16
%c6=bitcast i8*%c5 to i8*(i8*,i8*)**
%c7=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%c6,align 8
%c8=bitcast i8*%c4 to i8**
%c9=load i8*,i8**%c8,align 8
%da=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%db=getelementptr inbounds i8,i8*%da,i64 32
%dc=bitcast i8*%db to i8**
%dd=load i8*,i8**%dc,align 8
%de=call fastcc i8*%c7(i8*inreg%c9,i8*inreg%dd)
store i8*%de,i8**%j,align 8
%df=call i8*@sml_alloc(i32 inreg 12)#0
%dg=getelementptr inbounds i8,i8*%df,i64 -4
%dh=bitcast i8*%dg to i32*
store i32 1342177288,i32*%dh,align 4
store i8*%df,i8**%k,align 8
%di=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%dj=bitcast i8*%df to i8**
store i8*%di,i8**%dj,align 8
%dk=getelementptr inbounds i8,i8*%df,i64 8
%dl=bitcast i8*%dk to i32*
store i32 1,i32*%dl,align 4
%dm=call i8*@sml_alloc(i32 inreg 28)#0
%dn=getelementptr inbounds i8,i8*%dm,i64 -4
%do=bitcast i8*%dn to i32*
store i32 1342177304,i32*%do,align 4
store i8*%dm,i8**%j,align 8
%dp=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
%dq=bitcast i8*%dm to i8**
store i8*%dp,i8**%dq,align 8
%dr=getelementptr inbounds i8,i8*%dm,i64 8
%ds=bitcast i8*%dr to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL4pred_83 to void(...)*),void(...)**%ds,align 8
%dt=getelementptr inbounds i8,i8*%dm,i64 16
%du=bitcast i8*%dt to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL4pred_83 to void(...)*),void(...)**%du,align 8
%dv=getelementptr inbounds i8,i8*%dm,i64 24
%dw=bitcast i8*%dv to i32*
store i32 -2147483647,i32*%dw,align 4
%dx=call i8*@sml_alloc(i32 inreg 20)#0
%dy=getelementptr inbounds i8,i8*%dx,i64 -4
%dz=bitcast i8*%dy to i32*
store i32 1342177296,i32*%dz,align 4
%dA=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%dB=bitcast i8*%dx to i8**
store i8*%dA,i8**%dB,align 8
%dC=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%dD=getelementptr inbounds i8,i8*%dx,i64 8
%dE=bitcast i8*%dD to i8**
store i8*%dC,i8**%dE,align 8
%dF=getelementptr inbounds i8,i8*%dx,i64 16
%dG=bitcast i8*%dF to i32*
store i32 3,i32*%dG,align 4
%dH=call fastcc i8*@_SMLLN16ElaborateForeach2FnE_54(i8*inreg%dx)
store i8*%dH,i8**%g,align 8
%dI=load i8*,i8**%n,align 8
store i8*null,i8**%n,align 8
%dJ=bitcast i8**%e to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%dJ)
%dK=bitcast i8**%f to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%dK)
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%dI,i8**%e,align 8
%dL=call i8*@sml_alloc(i32 inreg 12)#0
%dM=getelementptr inbounds i8,i8*%dL,i64 -4
%dN=bitcast i8*%dM to i32*
store i32 1342177288,i32*%dN,align 4
store i8*%dL,i8**%f,align 8
%dO=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%dP=bitcast i8*%dL to i8**
store i8*%dO,i8**%dP,align 8
%dQ=getelementptr inbounds i8,i8*%dL,i64 8
%dR=bitcast i8*%dQ to i32*
store i32 1,i32*%dR,align 4
%dS=call i8*@sml_alloc(i32 inreg 28)#0
%dT=getelementptr inbounds i8,i8*%dS,i64 -4
%dU=bitcast i8*%dT to i32*
store i32 1342177304,i32*%dU,align 4
%dV=load i8*,i8**%f,align 8
%dW=bitcast i8*%dS to i8**
store i8*%dV,i8**%dW,align 8
%dX=getelementptr inbounds i8,i8*%dS,i64 8
%dY=bitcast i8*%dX to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach15Fun__ForeachDataE_70 to void(...)*),void(...)**%dY,align 8
%dZ=getelementptr inbounds i8,i8*%dS,i64 16
%d0=bitcast i8*%dZ to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach15Fun__ForeachDataE_70 to void(...)*),void(...)**%d0,align 8
%d1=getelementptr inbounds i8,i8*%dS,i64 24
%d2=bitcast i8*%d1 to i32*
store i32 -2147483647,i32*%d2,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%dJ)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%dK)
%d3=load i8*,i8**%m,align 8
store i8*null,i8**%m,align 8
%d4=call fastcc i8*@_SMLLN16ElaborateForeach15Fun__ForeachDataE_70(i8*inreg%dV,i8*inreg%d3)
%d5=getelementptr inbounds i8,i8*%d4,i64 16
%d6=bitcast i8*%d5 to i8*(i8*,i8*)**
%d7=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%d6,align 8
%d8=bitcast i8*%d4 to i8**
%d9=load i8*,i8**%d8,align 8
%ea=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%eb=call fastcc i8*%d7(i8*inreg%d9,i8*inreg%ea)
%ec=getelementptr inbounds i8,i8*%eb,i64 16
%ed=bitcast i8*%ec to i8*(i8*,i8*)**
%ee=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ed,align 8
%ef=bitcast i8*%eb to i8**
%eg=load i8*,i8**%ef,align 8
%eh=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%ei=call fastcc i8*%ee(i8*inreg%eg,i8*inreg%eh)
%ej=getelementptr inbounds i8,i8*%ei,i64 16
%ek=bitcast i8*%ej to i8*(i8*,i8*)**
%el=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ek,align 8
%em=bitcast i8*%ei to i8**
%en=load i8*,i8**%em,align 8
%eo=load i8*,i8**%i,align 8
%ep=getelementptr inbounds i8,i8*%eo,i64 8
%eq=bitcast i8*%ep to i8**
%er=load i8*,i8**%eq,align 8
%es=tail call fastcc i8*%el(i8*inreg%en,i8*inreg%er)
ret i8*%es
et:
%eu=getelementptr inbounds i8,i8*%w,i64 8
%ev=bitcast i8*%eu to i8**
%ew=load i8*,i8**%ev,align 8
store i8*%ew,i8**%j,align 8
%ex=bitcast i8**%k to i8***
%ey=load i8**,i8***%ex,align 8
%ez=load i8*,i8**%ey,align 8
%eA=getelementptr inbounds i8,i8*%ez,i64 8
%eB=bitcast i8*%eA to i8**
%eC=load i8*,i8**%eB,align 8
%eD=getelementptr inbounds i8,i8*%eC,i64 16
%eE=bitcast i8*%eD to i8*(i8*,i8*)**
%eF=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%eE,align 8
%eG=bitcast i8*%eC to i8**
%eH=load i8*,i8**%eG,align 8
%eI=getelementptr inbounds i8,i8*%ew,i64 24
%eJ=bitcast i8*%eI to i8**
%eK=load i8*,i8**%eJ,align 8
%eL=call fastcc i8*%eF(i8*inreg%eH,i8*inreg%eK)
store i8*%eL,i8**%g,align 8
%eM=call i8*@sml_alloc(i32 inreg 12)#0
%eN=getelementptr inbounds i8,i8*%eM,i64 -4
%eO=bitcast i8*%eN to i32*
store i32 1342177288,i32*%eO,align 4
store i8*%eM,i8**%h,align 8
%eP=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%eQ=bitcast i8*%eM to i8**
store i8*%eP,i8**%eQ,align 8
%eR=getelementptr inbounds i8,i8*%eM,i64 8
%eS=bitcast i8*%eR to i32*
store i32 1,i32*%eS,align 4
%eT=call i8*@sml_alloc(i32 inreg 28)#0
%eU=getelementptr inbounds i8,i8*%eT,i64 -4
%eV=bitcast i8*%eU to i32*
store i32 1342177304,i32*%eV,align 4
store i8*%eT,i8**%l,align 8
%eW=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%eX=bitcast i8*%eT to i8**
store i8*%eW,i8**%eX,align 8
%eY=getelementptr inbounds i8,i8*%eT,i64 8
%eZ=bitcast i8*%eY to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL3pat_73 to void(...)*),void(...)**%eZ,align 8
%e0=getelementptr inbounds i8,i8*%eT,i64 16
%e1=bitcast i8*%e0 to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL3pat_73 to void(...)*),void(...)**%e1,align 8
%e2=getelementptr inbounds i8,i8*%eT,i64 24
%e3=bitcast i8*%e2 to i32*
store i32 -2147483647,i32*%e3,align 4
%e4=load i8*,i8**%j,align 8
%e5=getelementptr inbounds i8,i8*%e4,i64 8
%e6=bitcast i8*%e5 to i8**
%e7=load i8*,i8**%e6,align 8
store i8*%e7,i8**%g,align 8
%e8=call i8*@sml_alloc(i32 inreg 12)#0
%e9=getelementptr inbounds i8,i8*%e8,i64 -4
%fa=bitcast i8*%e9 to i32*
store i32 1342177288,i32*%fa,align 4
store i8*%e8,i8**%h,align 8
%fb=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%fc=bitcast i8*%e8 to i8**
store i8*%fb,i8**%fc,align 8
%fd=getelementptr inbounds i8,i8*%e8,i64 8
%fe=bitcast i8*%fd to i32*
store i32 1,i32*%fe,align 4
%ff=call i8*@sml_alloc(i32 inreg 28)#0
%fg=getelementptr inbounds i8,i8*%ff,i64 -4
%fh=bitcast i8*%fg to i32*
store i32 1342177304,i32*%fh,align 4
store i8*%ff,i8**%g,align 8
%fi=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%fj=bitcast i8*%ff to i8**
store i8*%fi,i8**%fj,align 8
%fk=getelementptr inbounds i8,i8*%ff,i64 8
%fl=bitcast i8*%fk to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL5idPat_74 to void(...)*),void(...)**%fl,align 8
%fm=getelementptr inbounds i8,i8*%ff,i64 16
%fn=bitcast i8*%fm to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL5idPat_74 to void(...)*),void(...)**%fn,align 8
%fo=getelementptr inbounds i8,i8*%ff,i64 24
%fp=bitcast i8*%fo to i32*
store i32 -2147483647,i32*%fp,align 4
%fq=call i8*@sml_alloc(i32 inreg 20)#0
%fr=getelementptr inbounds i8,i8*%fq,i64 -4
%fs=bitcast i8*%fr to i32*
store i32 1342177296,i32*%fs,align 4
store i8*%fq,i8**%h,align 8
%ft=load i8*,i8**%l,align 8
store i8*null,i8**%l,align 8
%fu=bitcast i8*%fq to i8**
store i8*%ft,i8**%fu,align 8
%fv=getelementptr inbounds i8,i8*%fq,i64 8
%fw=bitcast i8*%fv to i8**
store i8*null,i8**%fw,align 8
%fx=getelementptr inbounds i8,i8*%fq,i64 16
%fy=bitcast i8*%fx to i32*
store i32 3,i32*%fy,align 4
%fz=call i8*@sml_alloc(i32 inreg 20)#0
%fA=getelementptr inbounds i8,i8*%fz,i64 -4
%fB=bitcast i8*%fA to i32*
store i32 1342177296,i32*%fB,align 4
store i8*%fz,i8**%l,align 8
%fC=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%fD=bitcast i8*%fz to i8**
store i8*%fC,i8**%fD,align 8
%fE=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%fF=getelementptr inbounds i8,i8*%fz,i64 8
%fG=bitcast i8*%fF to i8**
store i8*%fE,i8**%fG,align 8
%fH=getelementptr inbounds i8,i8*%fz,i64 16
%fI=bitcast i8*%fH to i32*
store i32 3,i32*%fI,align 4
%fJ=call fastcc i8*@_SMLFN11RecordLabel9tupleListE(i32 inreg 1,i32 inreg 8)
%fK=getelementptr inbounds i8,i8*%fJ,i64 16
%fL=bitcast i8*%fK to i8*(i8*,i8*)**
%fM=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%fL,align 8
%fN=bitcast i8*%fJ to i8**
%fO=load i8*,i8**%fN,align 8
%fP=load i8*,i8**%l,align 8
store i8*null,i8**%l,align 8
%fQ=call fastcc i8*%fM(i8*inreg%fO,i8*inreg%fP)
%fR=call fastcc i8*@_SMLLN16ElaborateForeach9PatRecordE_51(i8*inreg%fQ)
store i8*%fR,i8**%g,align 8
%fS=bitcast i8**%k to i8****
%fT=load i8***,i8****%fS,align 8
%fU=load i8**,i8***%fT,align 8
%fV=load i8*,i8**%fU,align 8
%fW=getelementptr inbounds i8,i8*%fV,i64 16
%fX=bitcast i8*%fW to i8*(i8*,i8*)**
%fY=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%fX,align 8
%fZ=bitcast i8*%fV to i8**
%f0=load i8*,i8**%fZ,align 8
%f1=bitcast i8**%j to i8***
%f2=load i8**,i8***%f1,align 8
%f3=load i8*,i8**%f2,align 8
%f4=call fastcc i8*%fY(i8*inreg%f0,i8*inreg%f3)
store i8*%f4,i8**%h,align 8
%f5=call i8*@sml_alloc(i32 inreg 12)#0
%f6=getelementptr inbounds i8,i8*%f5,i64 -4
%f7=bitcast i8*%f6 to i32*
store i32 1342177288,i32*%f7,align 4
store i8*%f5,i8**%l,align 8
%f8=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%f9=bitcast i8*%f5 to i8**
store i8*%f8,i8**%f9,align 8
%ga=getelementptr inbounds i8,i8*%f5,i64 8
%gb=bitcast i8*%ga to i32*
store i32 1,i32*%gb,align 4
%gc=call i8*@sml_alloc(i32 inreg 28)#0
%gd=getelementptr inbounds i8,i8*%gc,i64 -4
%ge=bitcast i8*%gd to i32*
store i32 1342177304,i32*%ge,align 4
store i8*%gc,i8**%m,align 8
%gf=load i8*,i8**%l,align 8
store i8*null,i8**%l,align 8
%gg=bitcast i8*%gc to i8**
store i8*%gf,i8**%gg,align 8
%gh=getelementptr inbounds i8,i8*%gc,i64 8
%gi=bitcast i8*%gh to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL4data_75 to void(...)*),void(...)**%gi,align 8
%gj=getelementptr inbounds i8,i8*%gc,i64 16
%gk=bitcast i8*%gj to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL4data_75 to void(...)*),void(...)**%gk,align 8
%gl=getelementptr inbounds i8,i8*%gc,i64 24
%gm=bitcast i8*%gl to i32*
store i32 -2147483647,i32*%gm,align 4
%gn=load i8***,i8****%fS,align 8
%go=load i8**,i8***%gn,align 8
%gp=load i8*,i8**%go,align 8
%gq=getelementptr inbounds i8,i8*%gp,i64 16
%gr=bitcast i8*%gq to i8*(i8*,i8*)**
%gs=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%gr,align 8
%gt=bitcast i8*%gp to i8**
%gu=load i8*,i8**%gt,align 8
%gv=load i8*,i8**%j,align 8
%gw=getelementptr inbounds i8,i8*%gv,i64 16
%gx=bitcast i8*%gw to i8**
%gy=load i8*,i8**%gx,align 8
%gz=call fastcc i8*%gs(i8*inreg%gu,i8*inreg%gy)
store i8*%gz,i8**%h,align 8
%gA=call i8*@sml_alloc(i32 inreg 12)#0
%gB=getelementptr inbounds i8,i8*%gA,i64 -4
%gC=bitcast i8*%gB to i32*
store i32 1342177288,i32*%gC,align 4
store i8*%gA,i8**%l,align 8
%gD=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%gE=bitcast i8*%gA to i8**
store i8*%gD,i8**%gE,align 8
%gF=getelementptr inbounds i8,i8*%gA,i64 8
%gG=bitcast i8*%gF to i32*
store i32 1,i32*%gG,align 4
%gH=call i8*@sml_alloc(i32 inreg 28)#0
%gI=getelementptr inbounds i8,i8*%gH,i64 -4
%gJ=bitcast i8*%gI to i32*
store i32 1342177304,i32*%gJ,align 4
store i8*%gH,i8**%h,align 8
%gK=load i8*,i8**%l,align 8
store i8*null,i8**%l,align 8
%gL=bitcast i8*%gH to i8**
store i8*%gK,i8**%gL,align 8
%gM=getelementptr inbounds i8,i8*%gH,i64 8
%gN=bitcast i8*%gM to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL8iterator_76 to void(...)*),void(...)**%gN,align 8
%gO=getelementptr inbounds i8,i8*%gH,i64 16
%gP=bitcast i8*%gO to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL8iterator_76 to void(...)*),void(...)**%gP,align 8
%gQ=getelementptr inbounds i8,i8*%gH,i64 24
%gR=bitcast i8*%gQ to i32*
store i32 -2147483647,i32*%gR,align 4
%gS=call i8*@sml_alloc(i32 inreg 20)#0
%gT=getelementptr inbounds i8,i8*%gS,i64 -4
%gU=bitcast i8*%gT to i32*
store i32 1342177296,i32*%gU,align 4
%gV=load i8*,i8**%g,align 8
%gW=bitcast i8*%gS to i8**
store i8*%gV,i8**%gW,align 8
%gX=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%gY=getelementptr inbounds i8,i8*%gS,i64 8
%gZ=bitcast i8*%gY to i8**
store i8*%gX,i8**%gZ,align 8
%g0=getelementptr inbounds i8,i8*%gS,i64 16
%g1=bitcast i8*%g0 to i32*
store i32 3,i32*%g1,align 4
%g2=call fastcc i8*@_SMLLN16ElaborateForeach2FnE_54(i8*inreg%gS)
store i8*%g2,i8**%h,align 8
%g3=load i8***,i8****%fS,align 8
store i8*null,i8**%k,align 8
%g4=load i8**,i8***%g3,align 8
%g5=load i8*,i8**%g4,align 8
%g6=getelementptr inbounds i8,i8*%g5,i64 16
%g7=bitcast i8*%g6 to i8*(i8*,i8*)**
%g8=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%g7,align 8
%g9=bitcast i8*%g5 to i8**
%ha=load i8*,i8**%g9,align 8
%hb=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%hc=getelementptr inbounds i8,i8*%hb,i64 32
%hd=bitcast i8*%hc to i8**
%he=load i8*,i8**%hd,align 8
%hf=call fastcc i8*%g8(i8*inreg%ha,i8*inreg%he)
store i8*%hf,i8**%j,align 8
%hg=call i8*@sml_alloc(i32 inreg 12)#0
%hh=getelementptr inbounds i8,i8*%hg,i64 -4
%hi=bitcast i8*%hh to i32*
store i32 1342177288,i32*%hi,align 4
store i8*%hg,i8**%k,align 8
%hj=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%hk=bitcast i8*%hg to i8**
store i8*%hj,i8**%hk,align 8
%hl=getelementptr inbounds i8,i8*%hg,i64 8
%hm=bitcast i8*%hl to i32*
store i32 1,i32*%hm,align 4
%hn=call i8*@sml_alloc(i32 inreg 28)#0
%ho=getelementptr inbounds i8,i8*%hn,i64 -4
%hp=bitcast i8*%ho to i32*
store i32 1342177304,i32*%hp,align 4
store i8*%hn,i8**%j,align 8
%hq=load i8*,i8**%k,align 8
store i8*null,i8**%k,align 8
%hr=bitcast i8*%hn to i8**
store i8*%hq,i8**%hr,align 8
%hs=getelementptr inbounds i8,i8*%hn,i64 8
%ht=bitcast i8*%hs to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL4pred_77 to void(...)*),void(...)**%ht,align 8
%hu=getelementptr inbounds i8,i8*%hn,i64 16
%hv=bitcast i8*%hu to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL4pred_77 to void(...)*),void(...)**%hv,align 8
%hw=getelementptr inbounds i8,i8*%hn,i64 24
%hx=bitcast i8*%hw to i32*
store i32 -2147483647,i32*%hx,align 4
%hy=call i8*@sml_alloc(i32 inreg 20)#0
%hz=getelementptr inbounds i8,i8*%hy,i64 -4
%hA=bitcast i8*%hz to i32*
store i32 1342177296,i32*%hA,align 4
%hB=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%hC=bitcast i8*%hy to i8**
store i8*%hB,i8**%hC,align 8
%hD=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%hE=getelementptr inbounds i8,i8*%hy,i64 8
%hF=bitcast i8*%hE to i8**
store i8*%hD,i8**%hF,align 8
%hG=getelementptr inbounds i8,i8*%hy,i64 16
%hH=bitcast i8*%hG to i32*
store i32 3,i32*%hH,align 4
%hI=call fastcc i8*@_SMLLN16ElaborateForeach2FnE_54(i8*inreg%hy)
store i8*%hI,i8**%g,align 8
%hJ=load i8*,i8**%m,align 8
store i8*null,i8**%m,align 8
%hK=bitcast i8**%c to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%hK)
%hL=bitcast i8**%d to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%hL)
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%hJ,i8**%c,align 8
%hM=call i8*@sml_alloc(i32 inreg 12)#0
%hN=getelementptr inbounds i8,i8*%hM,i64 -4
%hO=bitcast i8*%hN to i32*
store i32 1342177288,i32*%hO,align 4
store i8*%hM,i8**%d,align 8
%hP=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%hQ=bitcast i8*%hM to i8**
store i8*%hP,i8**%hQ,align 8
%hR=getelementptr inbounds i8,i8*%hM,i64 8
%hS=bitcast i8*%hR to i32*
store i32 1,i32*%hS,align 4
%hT=call i8*@sml_alloc(i32 inreg 28)#0
%hU=getelementptr inbounds i8,i8*%hT,i64 -4
%hV=bitcast i8*%hU to i32*
store i32 1342177304,i32*%hV,align 4
%hW=load i8*,i8**%d,align 8
%hX=bitcast i8*%hT to i8**
store i8*%hW,i8**%hX,align 8
%hY=getelementptr inbounds i8,i8*%hT,i64 8
%hZ=bitcast i8*%hY to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach15Fun__FoeachArrayE_63 to void(...)*),void(...)**%hZ,align 8
%h0=getelementptr inbounds i8,i8*%hT,i64 16
%h1=bitcast i8*%h0 to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach15Fun__FoeachArrayE_63 to void(...)*),void(...)**%h1,align 8
%h2=getelementptr inbounds i8,i8*%hT,i64 24
%h3=bitcast i8*%h2 to i32*
store i32 -2147483647,i32*%h3,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%hK)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%hL)
%h4=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%h5=call fastcc i8*@_SMLLN16ElaborateForeach15Fun__FoeachArrayE_63(i8*inreg%hW,i8*inreg%h4)
%h6=getelementptr inbounds i8,i8*%h5,i64 16
%h7=bitcast i8*%h6 to i8*(i8*,i8*)**
%h8=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%h7,align 8
%h9=bitcast i8*%h5 to i8**
%ia=load i8*,i8**%h9,align 8
%ib=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%ic=call fastcc i8*%h8(i8*inreg%ia,i8*inreg%ib)
%id=getelementptr inbounds i8,i8*%ic,i64 16
%ie=bitcast i8*%id to i8*(i8*,i8*)**
%if=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ie,align 8
%ig=bitcast i8*%ic to i8**
%ih=load i8*,i8**%ig,align 8
%ii=load i8*,i8**%i,align 8
%ij=getelementptr inbounds i8,i8*%ii,i64 8
%ik=bitcast i8*%ij to i8**
%il=load i8*,i8**%ik,align 8
%im=tail call fastcc i8*%if(i8*inreg%ih,i8*inreg%il)
ret i8*%im
}
define fastcc i8*@_SMLFN16ElaborateForeach12elaborateExpE(i8*inreg%a)#4 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
%d=call i8*@sml_alloc(i32 inreg 12)#0
%e=getelementptr inbounds i8,i8*%d,i64 -4
%f=bitcast i8*%e to i32*
store i32 1342177288,i32*%f,align 4
store i8*%d,i8**%c,align 8
%g=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%h=bitcast i8*%d to i8**
store i8*%g,i8**%h,align 8
%i=getelementptr inbounds i8,i8*%d,i64 8
%j=bitcast i8*%i to i32*
store i32 1,i32*%j,align 4
%k=call i8*@sml_alloc(i32 inreg 28)#0
%l=getelementptr inbounds i8,i8*%k,i64 -4
%m=bitcast i8*%l to i32*
store i32 1342177304,i32*%m,align 4
%n=load i8*,i8**%c,align 8
%o=bitcast i8*%k to i8**
store i8*%n,i8**%o,align 8
%p=getelementptr inbounds i8,i8*%k,i64 8
%q=bitcast i8*%p to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach12elaborateExpE_85 to void(...)*),void(...)**%q,align 8
%r=getelementptr inbounds i8,i8*%k,i64 16
%s=bitcast i8*%r to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN16ElaborateForeach12elaborateExpE_85 to void(...)*),void(...)**%s,align 8
%t=getelementptr inbounds i8,i8*%k,i64 24
%u=bitcast i8*%t to i32*
store i32 -2147483647,i32*%u,align 4
ret i8*%k
}
define internal fastcc i8*@_SMLLN16ElaborateForeach15Fun__FoeachArrayE_91(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLLN16ElaborateForeach15Fun__FoeachArrayE_60(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLN16ElaborateForeach15Fun__ForeachDataE_93(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLLN16ElaborateForeach15Fun__ForeachDataE_66(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLN16ElaborateForeach12elaborateExpE_95(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN16ElaborateForeach12elaborateExpE(i8*inreg%b)
ret i8*%c
}
declare void@llvm.lifetime.start.p0i8(i64,i8*)#0
declare void@llvm.lifetime.end.p0i8(i64,i8*)#0
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
attributes#4={nounwind uwtable}
