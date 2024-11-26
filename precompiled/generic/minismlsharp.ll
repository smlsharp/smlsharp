@sml_check_flag=external local_unnamed_addr global i32
@a=private unnamed_addr constant<{[4x i8],i32,[5x i8]}><{[4x i8]zeroinitializer,i32 -2147483643,[5x i8]c"Bind\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[5x i8]}>,<{[4x i8],i32,[5x i8]}>*@a,i32 0,i32 0,i32 0),i32 8),i32 0,[4x i8]zeroinitializer,i32 1}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@b,i32 0,i32 0,i32 0),i32 8)}>,align 8
@_SMLZ4Bind=unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@c,i64 0,i32 2)to i8*)
@d=private unnamed_addr constant<{[4x i8],i32,[6x i8]}><{[4x i8]zeroinitializer,i32 -2147483642,[6x i8]c"Match\00"}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[6x i8]}>,<{[4x i8],i32,[6x i8]}>*@d,i32 0,i32 0,i32 0),i32 8),i32 0,[4x i8]zeroinitializer,i32 1}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@e,i32 0,i32 0,i32 0),i32 8)}>,align 8
@_SMLZ5Match=unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@f,i64 0,i32 2)to i8*)
@g=private unnamed_addr constant<{[4x i8],i32,[10x i8]}><{[4x i8]zeroinitializer,i32 -2147483638,[10x i8]c"Subscript\00"}>,align 8
@h=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[10x i8]}>,<{[4x i8],i32,[10x i8]}>*@g,i32 0,i32 0,i32 0),i32 8),i32 0,[4x i8]zeroinitializer,i32 1}>,align 8
@i=private unnamed_addr constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@h,i32 0,i32 0,i32 0),i32 8)}>,align 8
@_SMLZ9Subscript=unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@i,i64 0,i32 2)to i8*)
@j=private unnamed_addr constant<{[4x i8],i32,[5x i8]}><{[4x i8]zeroinitializer,i32 -2147483643,[5x i8]c"Size\00"}>,align 8
@k=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[5x i8]}>,<{[4x i8],i32,[5x i8]}>*@j,i32 0,i32 0,i32 0),i32 8),i32 0,[4x i8]zeroinitializer,i32 1}>,align 8
@l=private unnamed_addr constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@k,i32 0,i32 0,i32 0),i32 8)}>,align 8
@_SMLZ4Size=unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@l,i64 0,i32 2)to i8*)
@m=private unnamed_addr constant<{[4x i8],i32,[9x i8]}><{[4x i8]zeroinitializer,i32 -2147483639,[9x i8]c"Overflow\00"}>,align 8
@n=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[9x i8]}>,<{[4x i8],i32,[9x i8]}>*@m,i32 0,i32 0,i32 0),i32 8),i32 0,[4x i8]zeroinitializer,i32 1}>,align 8
@o=private unnamed_addr constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@n,i32 0,i32 0,i32 0),i32 8)}>,align 8
@_SMLZ8Overflow=unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@o,i64 0,i32 2)to i8*)
@p=private unnamed_addr constant<{[4x i8],i32,[4x i8]}><{[4x i8]zeroinitializer,i32 -2147483644,[4x i8]c"Div\00"}>,align 8
@q=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[4x i8]}>,<{[4x i8],i32,[4x i8]}>*@p,i32 0,i32 0,i32 0),i32 8),i32 0,[4x i8]zeroinitializer,i32 1}>,align 8
@r=private unnamed_addr constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@q,i32 0,i32 0,i32 0),i32 8)}>,align 8
@_SMLZ3Div=unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@r,i64 0,i32 2)to i8*)
@s=private unnamed_addr constant<{[4x i8],i32,[7x i8]}><{[4x i8]zeroinitializer,i32 -2147483641,[7x i8]c"Domain\00"}>,align 8
@t=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[7x i8]}>,<{[4x i8],i32,[7x i8]}>*@s,i32 0,i32 0,i32 0),i32 8),i32 0,[4x i8]zeroinitializer,i32 1}>,align 8
@u=private unnamed_addr constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@t,i32 0,i32 0,i32 0),i32 8)}>,align 8
@_SMLZ6Domain=unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@u,i64 0,i32 2)to i8*)
@v=private unnamed_addr constant<{[4x i8],i32,[5x i8]}><{[4x i8]zeroinitializer,i32 -2147483643,[5x i8]c"Fail\00"}>,align 8
@w=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[5x i8]}>,<{[4x i8],i32,[5x i8]}>*@v,i32 0,i32 0,i32 0),i32 8),i32 16,[4x i8]zeroinitializer,i32 1}>,align 8
@x=private unnamed_addr constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@w,i32 0,i32 0,i32 0),i32 8)}>,align 8
@_SMLZ4Fail=unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@x,i64 0,i32 2)to i8*)
@y=private unnamed_addr constant<{[4x i8],i32,[4x i8]}><{[4x i8]zeroinitializer,i32 -2147483644,[4x i8]c"Chr\00"}>,align 8
@z=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[4x i8]}>,<{[4x i8],i32,[4x i8]}>*@y,i32 0,i32 0,i32 0),i32 8),i32 0,[4x i8]zeroinitializer,i32 1}>,align 8
@A=private unnamed_addr constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@z,i32 0,i32 0,i32 0),i32 8)}>,align 8
@_SMLZ3Chr=unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@A,i64 0,i32 2)to i8*)
@_SML_ftab5fac15a8929b5111_minismlsharp=external global i8
@B=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_end()local_unnamed_addr#0
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i32@sml_personality(...)#0
declare void@sml_save_exn(i8*inreg)local_unnamed_addr#0
declare void@sml_start(i8*inreg)local_unnamed_addr#0
declare i8*@_SMLFN11CommandLine4nameE(i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN11CommandLine9argumentsE(i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN18SMLSharp__OSProcess4exitE(i32 inreg,i32 inreg)local_unnamed_addr#1 gc"smlsharp"
declare i32@_SMLFN4Main4mainE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
define void@sml_load(i8*%a)local_unnamed_addr#0{
tail call void@_SML_load5fac15a8929b5111_minismlsharp(i8*%a)#3
ret void
}
define void@sml_main()local_unnamed_addr{
tail call void@_SML_main5fac15a8929b5111_minismlsharp()#3
ret void
}
declare void@_SML_main19a59bcdb325454c_SMLSharp_OSProcess()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main3b03551f42df3061_CommandLine()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main934c6dfb682db306_MiniMain()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_load19a59bcdb325454c_SMLSharp_OSProcess(i8*)local_unnamed_addr
declare void@_SML_load3b03551f42df3061_CommandLine(i8*)local_unnamed_addr
declare void@_SML_load934c6dfb682db306_MiniMain(i8*)local_unnamed_addr
define private void@_SML_tabb5fac15a8929b5111_minismlsharp()#2{
unreachable
}
define void@_SML_load5fac15a8929b5111_minismlsharp(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@B,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@B,align 1
tail call void@_SML_load19a59bcdb325454c_SMLSharp_OSProcess(i8*%a)#0
tail call void@_SML_load3b03551f42df3061_CommandLine(i8*%a)#0
tail call void@_SML_load934c6dfb682db306_MiniMain(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb5fac15a8929b5111_minismlsharp,i8*@_SML_ftab5fac15a8929b5111_minismlsharp,i8*null)#0
ret void
}
define void@_SML_main5fac15a8929b5111_minismlsharp()local_unnamed_addr#1 gc"smlsharp"personality i32(...)*@sml_personality{
%a=alloca[3x i8*],align 8
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=load i8,i8*@B,align 1
%e=and i8%d,2
%f=icmp eq i8%e,0
br i1%f,label%h,label%g
g:
ret void
h:
store i8 3,i8*@B,align 1
tail call void@_SML_main19a59bcdb325454c_SMLSharp_OSProcess()#1
tail call void@_SML_main3b03551f42df3061_CommandLine()#1
tail call void@_SML_main934c6dfb682db306_MiniMain()#1
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
%i=bitcast[3x i8*]*%a to i8*
call void@sml_start(i8*inreg%i)#0
%j=load atomic i32,i32*@sml_check_flag unordered,align 4
%k=icmp eq i32%j,0
br i1%k,label%m,label%l
l:
invoke void@sml_check(i32 inreg%j)
to label%m unwind label%R
m:
%n=invoke fastcc i8*@_SMLFN11CommandLine4nameE(i32 inreg 0)
to label%o unwind label%R
o:
store i8*%n,i8**%b,align 8
%p=invoke fastcc i8*@_SMLFN11CommandLine9argumentsE(i32 inreg 0)
to label%q unwind label%R
q:
store i8*%p,i8**%c,align 8
%r=call i8*@sml_alloc(i32 inreg 20)#0
%s=getelementptr inbounds i8,i8*%r,i64 -4
%t=bitcast i8*%s to i32*
store i32 1342177296,i32*%t,align 4
%u=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%v=bitcast i8*%r to i8**
store i8*%u,i8**%v,align 8
%w=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%x=getelementptr inbounds i8,i8*%r,i64 8
%y=bitcast i8*%x to i8**
store i8*%w,i8**%y,align 8
%z=getelementptr inbounds i8,i8*%r,i64 16
%A=bitcast i8*%z to i32*
store i32 3,i32*%A,align 4
%B=invoke fastcc i32@_SMLFN4Main4mainE(i8*inreg%r)
to label%C unwind label%R
C:
%D=invoke fastcc i8*@_SMLFN18SMLSharp__OSProcess4exitE(i32 inreg 0,i32 inreg 4)
to label%E unwind label%R
E:
%F=getelementptr inbounds i8,i8*%D,i64 16
%G=bitcast i8*%F to i8*(i8*,i8*)**
%H=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%G,align 8
%I=bitcast i8*%D to i8**
%J=load i8*,i8**%I,align 8
store i8*%J,i8**%b,align 8
%K=call i8*@sml_alloc(i32 inreg 4)#0
%L=bitcast i8*%K to i32*
%M=getelementptr inbounds i8,i8*%K,i64 -4
%N=bitcast i8*%M to i32*
store i32 4,i32*%N,align 4
store i32%B,i32*%L,align 4
%O=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%P=invoke fastcc i8*%H(i8*inreg%O,i8*inreg%K)
to label%Q unwind label%R
Q:
call void@sml_end()#0
ret void
R:
%S=landingpad{i8*,i8*}
cleanup
%T=extractvalue{i8*,i8*}%S,1
call void@sml_save_exn(i8*inreg%T)#0
call void@sml_end()#0
resume{i8*,i8*}%S
}
attributes#0={nounwind}
attributes#1={uwtable}
attributes#2={noreturn nounwind}
attributes#3={noinline uwtable}
