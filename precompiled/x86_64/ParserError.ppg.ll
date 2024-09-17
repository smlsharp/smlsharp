@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN15BasicFormatters14format__exn__RefE=external local_unnamed_addr global i8*
@a=private unnamed_addr constant<{[4x i8],i32,[23x i8]}><{[4x i8]zeroinitializer,i32 -2147483625,[23x i8]c"ParserError.ParseError\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[23x i8]}>,<{[4x i8],i32,[23x i8]}>*@a,i32 0,i32 0,i32 0),i32 8),i32 16,[4x i8]zeroinitializer,i32 1}>,align 8
@_SMLDL32=private constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@b,i32 0,i32 0,i32 0),i32 8)}>,align 8
@_SMLZN11ParserError10ParseErrorE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL32,i64 0,i32 2)to i8*)
@_SML_ftab40724fe7152bd191_ParserError_ppg=external global i8
@c=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_end()local_unnamed_addr#0
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_start(i8*inreg)local_unnamed_addr#0
declare void@sml_write(i8*inreg,i8**inreg,i8*inreg)local_unnamed_addr#0
declare i8*@_SMLFN15BasicFormatters13format__stringE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main6ad4d8e473c26a9c_BasicFormatters()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_load6ad4d8e473c26a9c_BasicFormatters(i8*)local_unnamed_addr
define private void@_SML_tabb40724fe7152bd191_ParserError_ppg()#2{
unreachable
}
define void@_SML_load40724fe7152bd191_ParserError_ppg(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@c,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@c,align 1
tail call void@_SML_load6ad4d8e473c26a9c_BasicFormatters(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb40724fe7152bd191_ParserError_ppg,i8*@_SML_ftab40724fe7152bd191_ParserError_ppg,i8*null)#0
ret void
}
define void@_SML_main40724fe7152bd191_ParserError_ppg()local_unnamed_addr#1 gc"smlsharp"{
%a=alloca[3x i8*],align 8
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=load i8,i8*@c,align 1
%e=and i8%d,2
%f=icmp eq i8%e,0
br i1%f,label%h,label%g
g:
ret void
h:
store i8 3,i8*@c,align 1
tail call void@_SML_main6ad4d8e473c26a9c_BasicFormatters()#1
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
%i=bitcast[3x i8*]*%a to i8*
call void@sml_start(i8*inreg%i)#0
%j=load i8**,i8***bitcast(i8**@_SMLZN15BasicFormatters14format__exn__RefE to i8***),align 8
%k=load i8*,i8**%j,align 8
store i8*%k,i8**%b,align 8
%l=call i8*@sml_alloc(i32 inreg 12)#0
%m=getelementptr inbounds i8,i8*%l,i64 -4
%n=bitcast i8*%m to i32*
store i32 1342177288,i32*%n,align 4
store i8*%l,i8**%c,align 8
%o=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%p=bitcast i8*%l to i8**
store i8*%o,i8**%p,align 8
%q=getelementptr inbounds i8,i8*%l,i64 8
%r=bitcast i8*%q to i32*
store i32 1,i32*%r,align 4
%s=call i8*@sml_alloc(i32 inreg 28)#0
%t=getelementptr inbounds i8,i8*%s,i64 -4
%u=bitcast i8*%t to i32*
store i32 1342177304,i32*%u,align 4
%v=load i8*,i8**%c,align 8
%w=bitcast i8*%s to i8**
store i8*%v,i8**%w,align 8
%x=getelementptr inbounds i8,i8*%s,i64 8
%y=bitcast i8*%x to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11ParserError6formatE_33 to void(...)*),void(...)**%y,align 8
%z=getelementptr inbounds i8,i8*%s,i64 16
%A=bitcast i8*%z to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN11ParserError6formatE_33 to void(...)*),void(...)**%A,align 8
%B=getelementptr inbounds i8,i8*%s,i64 24
%C=bitcast i8*%B to i32*
store i32 -2147483647,i32*%C,align 4
%D=load i8*,i8**@_SMLZN15BasicFormatters14format__exn__RefE,align 8
%E=bitcast i8*%D to i8**
call void@sml_write(i8*inreg%D,i8**inreg%E,i8*inreg%s)#0
call void@sml_end()#0
ret void
}
define internal fastcc i8*@_SMLLN11ParserError6formatE_33(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
k:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%c,align 8
store i8*%b,i8**%d,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%i,label%g
g:
call void@sml_check(i32 inreg%e)
%h=load i8*,i8**%d,align 8
br label%i
i:
%j=phi i8*[%h,%g],[%b,%k]
%l=bitcast i8*%j to i8**
%m=load i8*,i8**%l,align 8
%n=icmp eq i8*%m,bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL32,i64 0,i32 2)to i8*)
br i1%n,label%o,label%t
o:
%p=getelementptr inbounds i8,i8*%j,i64 16
%q=bitcast i8*%p to i8**
%r=load i8*,i8**%q,align 8
%s=tail call fastcc i8*@_SMLFN15BasicFormatters13format__stringE(i8*inreg%r)
ret i8*%s
t:
%u=bitcast i8**%c to i8***
%v=load i8**,i8***%u,align 8
%w=load i8*,i8**%v,align 8
%x=getelementptr inbounds i8,i8*%w,i64 16
%y=bitcast i8*%x to i8*(i8*,i8*)**
%z=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%y,align 8
%A=bitcast i8*%w to i8**
%B=load i8*,i8**%A,align 8
%C=tail call fastcc i8*%z(i8*inreg%B,i8*inreg%j)
ret i8*%C
}
attributes#0={nounwind}
attributes#1={uwtable}
attributes#2={noreturn nounwind}
