@sml_check_flag=external local_unnamed_addr global i32
@a=private unnamed_addr constant<{[4x i8],i32,i32,i32,i32}><{[4x i8]zeroinitializer,i32 -805306360,i32 2,i32 2,i32 0}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i32,i32,i32}><{[4x i8]zeroinitializer,i32 -805306360,i32 1,i32 1,i32 0}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i32,i32,i32}><{[4x i8]zeroinitializer,i32 -805306360,i32 3,i32 13,i32 0}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i32,i32,i32}><{[4x i8]zeroinitializer,i32 -805306360,i32 0,i32 14,i32 0}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,i32,i32,i32}><{[4x i8]zeroinitializer,i32 -805306360,i32 4,i32 15,i32 0}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i32,i32,i32}>,<{[4x i8],i32,i32,i32,i32}>*@e,i32 0,i32 0,i32 0),i32 8),i8*null,i32 3}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i32,i32,i32}>,<{[4x i8],i32,i32,i32,i32}>*@d,i32 0,i32 0,i32 0),i32 8),i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@f,i32 0,i32 0,i32 0),i32 8),i32 3}>,align 8
@h=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i32,i32,i32}>,<{[4x i8],i32,i32,i32,i32}>*@c,i32 0,i32 0,i32 0),i32 8),i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@g,i32 0,i32 0,i32 0),i32 8),i32 3}>,align 8
@i=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i32,i32,i32}>,<{[4x i8],i32,i32,i32,i32}>*@b,i32 0,i32 0,i32 0),i32 8),i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@h,i32 0,i32 0,i32 0),i32 8),i32 3}>,align 8
@j=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i32,i32,i32}>,<{[4x i8],i32,i32,i32,i32}>*@a,i32 0,i32 0,i32 0),i32 8),i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@i,i32 0,i32 0,i32 0),i32 8),i32 3}>,align 8
@k=private unnamed_addr constant<{[4x i8],i32,[21x i8]}><{[4x i8]zeroinitializer,i32 -2147483627,[21x i8]c"SignalHandler.Signal\00"}>,align 8
@l=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[21x i8]}>,<{[4x i8],i32,[21x i8]}>*@k,i32 0,i32 0,i32 0),i32 8),i32 0,[4x i8]zeroinitializer,i32 1}>,align 8
@_SMLDL49=private constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@l,i32 0,i32 0,i32 0),i32 8)}>,align 8
@m=private unnamed_addr constant<{[4x i8],i32,[67x i8]}><{[4x i8]zeroinitializer,i32 -2147483581,[67x i8]c"src/compiler/compilePhases/main/main/SignalHandler.sml:46.14(1088)\00"}>,align 8
@n=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(void(i32)*@_SMLFN13SignalHandler4initE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN13SignalHandler4initE_61 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN13SignalHandler6SignalE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL49,i64 0,i32 2)to i8*)
@_SMLZN13SignalHandler4initE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@n,i64 0,i32 2)to i8*)
@o=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(void(i32)*@_SMLFN13SignalHandler4stopE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN13SignalHandler4stopE_62 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN13SignalHandler4stopE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@o,i64 0,i32 2)to i8*)
@_SML_ftabd4e7251cb282a392_SignalHandler=external global i8
@p=private unnamed_addr global i8 0
@q=internal unnamed_addr global i1 false,align 8
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_end()local_unnamed_addr#0
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i32@sml_personality(...)#0
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare void@sml_save_exn(i8*inreg)local_unnamed_addr#0
declare i32@sml_signal_check()local_unnamed_addr
declare i32@sml_signal_sigaction(void()*)local_unnamed_addr
declare void@sml_start(i8*inreg)local_unnamed_addr#0
declare i8*@_SMLFN16SMLSharp__Runtime9OS__SysErrE(i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List10mapPartialE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main00d884c96265bfea_SMLSharp_Runtime()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main03d87556ec7f64b2_List()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load00d884c96265bfea_SMLSharp_Runtime(i8*)local_unnamed_addr
declare void@_SML_load03d87556ec7f64b2_List(i8*)local_unnamed_addr
define private void@_SML_tabbd4e7251cb282a392_SignalHandler()#3{
unreachable
}
define void@_SML_loadd4e7251cb282a392_SignalHandler(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@p,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@p,align 1
tail call void@_SML_load00d884c96265bfea_SMLSharp_Runtime(i8*%a)#0
tail call void@_SML_load03d87556ec7f64b2_List(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbd4e7251cb282a392_SignalHandler,i8*@_SML_ftabd4e7251cb282a392_SignalHandler,i8*null)#0
ret void
}
define void@_SML_maind4e7251cb282a392_SignalHandler()local_unnamed_addr#2 gc"smlsharp"{
%a=load i8,i8*@p,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@p,align 1
tail call void@_SML_main00d884c96265bfea_SMLSharp_Runtime()#2
tail call void@_SML_main03d87556ec7f64b2_List()#2
br label%d
}
define internal fastcc i8*@_SMLL7signums_51(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=getelementptr inbounds i8,i8*%b,i64 4
%d=bitcast i8*%c to i32*
%e=load i32,i32*%d,align 4
%f=icmp ugt i32%e,31
%g=shl i32 1,%e
%h=select i1%f,i32 0,i32%g
%i=bitcast i8*%a to i32*
%j=load i32,i32*%i,align 4
%k=and i32%h,%j
%l=icmp eq i32%k,0
br i1%l,label%x,label%m
m:
%n=bitcast i8*%b to i32*
%o=load i32,i32*%n,align 4
%p=tail call i8*@sml_alloc(i32 inreg 12)#0
%q=bitcast i8*%p to i32*
%r=getelementptr inbounds i8,i8*%p,i64 -4
%s=bitcast i8*%r to i32*
store i32 1342177288,i32*%s,align 4
%t=getelementptr inbounds i8,i8*%p,i64 4
%u=bitcast i8*%t to i32*
store i32 0,i32*%u,align 1
store i32%o,i32*%q,align 4
%v=getelementptr inbounds i8,i8*%p,i64 8
%w=bitcast i8*%v to i32*
store i32 0,i32*%w,align 4
ret i8*%p
x:
ret i8*null
}
define internal void@_SMLBN13SignalHandler4initE_55()#2 gc"smlsharp"personality i32(...)*@sml_personality{
%a=alloca i8*,align 8
%b=alloca i8*,align 8
%c=alloca[3x i8*],align 8
%d=bitcast[3x i8*]*%c to i8*
call void@sml_start(i8*inreg%d)#0
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%h,label%g
g:
invoke void@sml_check(i32 inreg%e)
to label%h unwind label%au
h:
%i=bitcast i8**%a to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%i)
%j=bitcast i8**%b to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%j)
call void@llvm.gcroot(i8**%a,i8*null)#0
call void@llvm.gcroot(i8**%b,i8*null)#0
%k=load atomic i32,i32*@sml_check_flag unordered,align 4
%l=icmp eq i32%k,0
br i1%l,label%n,label%m
m:
invoke void@sml_check(i32 inreg%k)
to label%n unwind label%au
n:
%o=load i1,i1*@q,align 8
br i1%o,label%at,label%p
p:
%q=invoke i32@sml_signal_check()
to label%r unwind label%au
r:
%s=invoke fastcc i8*@_SMLFN4List10mapPartialE(i32 inreg 1,i32 inreg 8,i32 inreg 0,i32 inreg 4)
to label%t unwind label%au
t:
%u=getelementptr inbounds i8,i8*%s,i64 16
%v=bitcast i8*%u to i8*(i8*,i8*)**
%w=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%v,align 8
%x=bitcast i8*%s to i8**
%y=load i8*,i8**%x,align 8
store i8*%y,i8**%a,align 8
%z=call i8*@sml_alloc(i32 inreg 12)#0
%A=bitcast i8*%z to i32*
%B=getelementptr inbounds i8,i8*%z,i64 -4
%C=bitcast i8*%B to i32*
store i32 1342177288,i32*%C,align 4
store i8*%z,i8**%b,align 8
store i32%q,i32*%A,align 4
%D=getelementptr inbounds i8,i8*%z,i64 8
%E=bitcast i8*%D to i32*
store i32 0,i32*%E,align 4
%F=call i8*@sml_alloc(i32 inreg 28)#0
%G=getelementptr inbounds i8,i8*%F,i64 -4
%H=bitcast i8*%G to i32*
store i32 1342177304,i32*%H,align 4
%I=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%J=bitcast i8*%F to i8**
store i8*%I,i8**%J,align 8
%K=getelementptr inbounds i8,i8*%F,i64 8
%L=bitcast i8*%K to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL7signums_51 to void(...)*),void(...)**%L,align 8
%M=getelementptr inbounds i8,i8*%F,i64 16
%N=bitcast i8*%M to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLL7signums_51 to void(...)*),void(...)**%N,align 8
%O=getelementptr inbounds i8,i8*%F,i64 24
%P=bitcast i8*%O to i32*
store i32 -2147483647,i32*%P,align 4
%Q=load i8*,i8**%a,align 8
store i8*null,i8**%a,align 8
%R=invoke fastcc i8*%w(i8*inreg%Q,i8*inreg%F)
to label%S unwind label%au
S:
%T=getelementptr inbounds i8,i8*%R,i64 16
%U=bitcast i8*%T to i8*(i8*,i8*)**
%V=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%U,align 8
%W=bitcast i8*%R to i8**
%X=load i8*,i8**%W,align 8
%Y=invoke fastcc i8*%V(i8*inreg%X,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@j,i64 0,i32 2)to i8*))
to label%Z unwind label%au
Z:
store i8*%Y,i8**%a,align 8
%aa=call i8*@sml_alloc(i32 inreg 28)#0
%ab=getelementptr inbounds i8,i8*%aa,i64 -4
%ac=bitcast i8*%ab to i32*
store i32 1342177304,i32*%ac,align 4
store i8*%aa,i8**%b,align 8
%ad=bitcast i8*%aa to i8**
store i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL49,i64 0,i32 2)to i8*),i8**%ad,align 8
%ae=getelementptr inbounds i8,i8*%aa,i64 8
%af=bitcast i8*%ae to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[67x i8]}>,<{[4x i8],i32,[67x i8]}>*@m,i64 0,i32 2,i64 0),i8**%af,align 8
%ag=load i8*,i8**%a,align 8
store i8*null,i8**%a,align 8
%ah=getelementptr inbounds i8,i8*%aa,i64 16
%ai=bitcast i8*%ah to i8**
store i8*%ag,i8**%ai,align 8
%aj=getelementptr inbounds i8,i8*%aa,i64 24
%ak=bitcast i8*%aj to i32*
store i32 7,i32*%ak,align 4
%al=call i8*@sml_alloc(i32 inreg 60)#0
%am=getelementptr inbounds i8,i8*%al,i64 -4
%an=bitcast i8*%am to i32*
store i32 1342177336,i32*%an,align 4
%ao=getelementptr inbounds i8,i8*%al,i64 56
%ap=bitcast i8*%ao to i32*
store i32 1,i32*%ap,align 4
%aq=load i8*,i8**%b,align 8
%ar=bitcast i8*%al to i8**
store i8*%aq,i8**%ar,align 8
invoke void@sml_raise(i8*inreg%al)#1
to label%as unwind label%au
as:
unreachable
at:
call void@llvm.lifetime.end.p0i8(i64 8,i8*%i)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%j)
call void@sml_end()#0
ret void
au:
%av=landingpad{i8*,i8*}
cleanup
%aw=extractvalue{i8*,i8*}%av,1
call void@sml_save_exn(i8*inreg%aw)#0
call void@sml_end()#0
resume{i8*,i8*}%av
}
define fastcc void@_SMLFN13SignalHandler4initE(i32 inreg%a)#2 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=call i32@sml_signal_sigaction(void()*@_SMLBN13SignalHandler4initE_55)
%h=icmp eq i32%g,0
br i1%h,label%r,label%i
i:
%j=call fastcc i8*@_SMLFN16SMLSharp__Runtime9OS__SysErrE(i32 inreg 0)
store i8*%j,i8**%b,align 8
%k=call i8*@sml_alloc(i32 inreg 60)#0
%l=getelementptr inbounds i8,i8*%k,i64 -4
%m=bitcast i8*%l to i32*
store i32 1342177336,i32*%m,align 4
%n=getelementptr inbounds i8,i8*%k,i64 56
%o=bitcast i8*%n to i32*
store i32 1,i32*%o,align 4
%p=load i8*,i8**%b,align 8
%q=bitcast i8*%k to i8**
store i8*%p,i8**%q,align 8
call void@sml_raise(i8*inreg%k)#1
unreachable
r:
ret void
}
define fastcc void@_SMLFN13SignalHandler4stopE(i32 inreg%a)#4 gc"smlsharp"{
store i1 true,i1*@q,align 8
ret void
}
define internal fastcc i8*@_SMLLN13SignalHandler4initE_61(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
tail call fastcc void@_SMLFN13SignalHandler4initE(i32 inreg undef)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLN13SignalHandler4stopE_62(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
store i1 true,i1*@q,align 8
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
attributes#4={nounwind uwtable}
