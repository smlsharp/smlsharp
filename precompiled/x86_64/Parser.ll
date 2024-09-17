@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN11ParserError10ParseErrorE=external local_unnamed_addr global i8*
@_SMLZN14SMLSharpParser13sourceOfInputE=external local_unnamed_addr global i8*
@_SMLZN14SMLSharpParser5ErrorE=external local_unnamed_addr global i8*
@_SMLZN14SMLSharpParser5setupE=external local_unnamed_addr global i8*
@_SMLZN9UserError10UserErrorsE=external local_unnamed_addr global i8*
@a=private unnamed_addr constant<{[4x i8],i32,[61x i8]}><{[4x i8]zeroinitializer,i32 -2147483587,[61x i8]c"src/compiler/compilePhases/parser/main/Parser.sml:16.12(309)\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306360,i32 1,[4x i8]zeroinitializer,i32 0}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,[61x i8]}><{[4x i8]zeroinitializer,i32 -2147483587,[61x i8]c"src/compiler/compilePhases/parser/main/Parser.sml:17.58(388)\00"}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLLN6Parser15raiseUserErrorsE_33 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN6Parser15raiseUserErrorsE_45 to void(...)*),i32 -2147483647}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN6Parser5parseE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN6Parser5parseE_49 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN6Parser5parseE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@e,i64 0,i32 2)to i8*)
@f=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i32(i8*)*@_SMLFN6Parser5isEOFE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN6Parser5isEOFE_50 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN6Parser5isEOFE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@f,i64 0,i32 2)to i8*)
@_SML_gvar76f5db83044d8678_Parser=private global<{[4x i8],i32,[2x i8*]}><{[4x i8]zeroinitializer,i32 -1342177264,[2x i8*]zeroinitializer}>,align 8
@g=private unnamed_addr global[2x i64][i64 1,i64 sub(i64 ptrtoint(i8**getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar76f5db83044d8678_Parser,i32 0,i32 2,i32 0)to i64),i64 ptrtoint([2x i64]*@g to i64))]
@_SML_ftab76f5db83044d8678_Parser=external global i8
@h=private unnamed_addr global i8 0
@_SMLZN6Parser5setupE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar76f5db83044d8678_Parser,i32 0,i32 2,i32 0)
@_SMLZN6Parser13sourceOfInputE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar76f5db83044d8678_Parser,i32 0,i32 2,i32 1)
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_end()local_unnamed_addr#0
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i32@sml_personality(...)#0
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare void@sml_start(i8*inreg)local_unnamed_addr#0
declare void@sml_write(i8*inreg,i8**inreg,i8*inreg)local_unnamed_addr#0
declare i32@_SMLFN14SMLSharpParser5isEOFE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN14SMLSharpParser5parseE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List3mapE(i32 inreg,i32 inreg,i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main03d87556ec7f64b2_List()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_mainadeb402e3568875f_UserError_ppg()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main40724fe7152bd191_ParserError_ppg()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main8949b1c81ea530a1_SMLSharpParser()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load03d87556ec7f64b2_List(i8*)local_unnamed_addr
declare void@_SML_loadadeb402e3568875f_UserError_ppg(i8*)local_unnamed_addr
declare void@_SML_load40724fe7152bd191_ParserError_ppg(i8*)local_unnamed_addr
declare void@_SML_load8949b1c81ea530a1_SMLSharpParser(i8*)local_unnamed_addr
define private void@_SML_tabb76f5db83044d8678_Parser()#3{
unreachable
}
define void@_SML_load76f5db83044d8678_Parser(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@h,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@h,align 1
tail call void@_SML_load03d87556ec7f64b2_List(i8*%a)#0
tail call void@_SML_loadadeb402e3568875f_UserError_ppg(i8*%a)#0
tail call void@_SML_load40724fe7152bd191_ParserError_ppg(i8*%a)#0
tail call void@_SML_load8949b1c81ea530a1_SMLSharpParser(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb76f5db83044d8678_Parser,i8*@_SML_ftab76f5db83044d8678_Parser,i8*bitcast([2x i64]*@g to i8*))#0
ret void
}
define void@_SML_main76f5db83044d8678_Parser()local_unnamed_addr#2 gc"smlsharp"{
%a=alloca[3x i8*],align 8
%b=load i8,i8*@h,align 1
%c=and i8%b,2
%d=icmp eq i8%c,0
br i1%d,label%f,label%e
e:
ret void
f:
store i8 3,i8*@h,align 1
tail call void@_SML_main03d87556ec7f64b2_List()#2
tail call void@_SML_mainadeb402e3568875f_UserError_ppg()#2
tail call void@_SML_main40724fe7152bd191_ParserError_ppg()#2
tail call void@_SML_main8949b1c81ea530a1_SMLSharpParser()#2
%g=bitcast[3x i8*]*%a to i8*
call void@sml_start(i8*inreg%g)#0
%h=load i8*,i8**@_SMLZN14SMLSharpParser5setupE,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar76f5db83044d8678_Parser,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar76f5db83044d8678_Parser,i64 0,i32 2,i64 0),i8*inreg%h)#0
%i=load i8*,i8**@_SMLZN14SMLSharpParser13sourceOfInputE,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar76f5db83044d8678_Parser,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar76f5db83044d8678_Parser,i64 0,i32 2,i64 1),i8*inreg%i)#0
call void@sml_end()#0
ret void
}
define internal fastcc i8*@_SMLLN6Parser15raiseUserErrorsE_33(i8*inreg%a)#4 gc"smlsharp"{
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
%h=load i8*,i8**@_SMLZN11ParserError10ParseErrorE,align 8
store i8*%h,i8**%c,align 8
%i=getelementptr inbounds i8,i8*%a,i64 8
%j=bitcast i8*%i to i8**
%k=load i8*,i8**%j,align 8
store i8*%k,i8**%d,align 8
%l=call i8*@sml_alloc(i32 inreg 28)#0
%m=getelementptr inbounds i8,i8*%l,i64 -4
%n=bitcast i8*%m to i32*
store i32 1342177304,i32*%n,align 4
store i8*%l,i8**%e,align 8
%o=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%p=bitcast i8*%l to i8**
store i8*%o,i8**%p,align 8
%q=getelementptr inbounds i8,i8*%l,i64 8
%r=bitcast i8*%q to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@c,i64 0,i32 2,i64 0),i8**%r,align 8
%s=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%t=getelementptr inbounds i8,i8*%l,i64 16
%u=bitcast i8*%t to i8**
store i8*%s,i8**%u,align 8
%v=getelementptr inbounds i8,i8*%l,i64 24
%w=bitcast i8*%v to i32*
store i32 7,i32*%w,align 4
%x=call i8*@sml_alloc(i32 inreg 28)#0
%y=getelementptr inbounds i8,i8*%x,i64 -4
%z=bitcast i8*%y to i32*
store i32 1342177304,i32*%z,align 4
%A=load i8*,i8**%b,align 8
%B=bitcast i8*%x to i8**
store i8*%A,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%x,i64 8
%D=bitcast i8*%C to i8**
store i8*bitcast(i32*getelementptr inbounds(<{[4x i8],i32,i32,[4x i8],i32}>,<{[4x i8],i32,i32,[4x i8],i32}>*@b,i64 0,i32 2)to i8*),i8**%D,align 8
%E=load i8*,i8**%e,align 8
%F=getelementptr inbounds i8,i8*%x,i64 16
%G=bitcast i8*%F to i8**
store i8*%E,i8**%G,align 8
%H=getelementptr inbounds i8,i8*%x,i64 24
%I=bitcast i8*%H to i32*
store i32 7,i32*%I,align 4
ret i8*%x
}
define internal fastcc i8*@_SMLLN6Parser15raiseUserErrorsE_35(i8*inreg%a)unnamed_addr#5 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%b,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%h,label%g
g:
call void@sml_check(i32 inreg%e)
br label%h
h:
%i=load i8*,i8**@_SMLZN9UserError10UserErrorsE,align 8
store i8*%i,i8**%c,align 8
%j=call fastcc i8*@_SMLFN4List3mapE(i32 inreg 1,i32 inreg 8,i32 inreg 1,i32 inreg 8)
%k=getelementptr inbounds i8,i8*%j,i64 16
%l=bitcast i8*%k to i8*(i8*,i8*)**
%m=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%l,align 8
%n=bitcast i8*%j to i8**
%o=load i8*,i8**%n,align 8
%p=call fastcc i8*%m(i8*inreg%o,i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@d,i64 0,i32 2)to i8*))
%q=getelementptr inbounds i8,i8*%p,i64 16
%r=bitcast i8*%q to i8*(i8*,i8*)**
%s=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%r,align 8
%t=bitcast i8*%p to i8**
%u=load i8*,i8**%t,align 8
%v=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%w=call fastcc i8*%s(i8*inreg%u,i8*inreg%v)
store i8*%w,i8**%b,align 8
%x=call i8*@sml_alloc(i32 inreg 28)#0
%y=getelementptr inbounds i8,i8*%x,i64 -4
%z=bitcast i8*%y to i32*
store i32 1342177304,i32*%z,align 4
store i8*%x,i8**%d,align 8
%A=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%B=bitcast i8*%x to i8**
store i8*%A,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%x,i64 8
%D=bitcast i8*%C to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[61x i8]}>,<{[4x i8],i32,[61x i8]}>*@a,i64 0,i32 2,i64 0),i8**%D,align 8
%E=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%F=getelementptr inbounds i8,i8*%x,i64 16
%G=bitcast i8*%F to i8**
store i8*%E,i8**%G,align 8
%H=getelementptr inbounds i8,i8*%x,i64 24
%I=bitcast i8*%H to i32*
store i32 7,i32*%I,align 4
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
}
define fastcc i8*@_SMLFN6Parser5setupE(i8*inreg%a)local_unnamed_addr#2 gc"smlsharp"{
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
%j=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar76f5db83044d8678_Parser,i64 0,i32 2,i64 0),align 8
%k=getelementptr inbounds i8,i8*%j,i64 16
%l=bitcast i8*%k to i8*(i8*,i8*)**
%m=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%l,align 8
%n=bitcast i8*%j to i8**
%o=load i8*,i8**%n,align 8
%p=tail call fastcc i8*%m(i8*inreg%o,i8*inreg%h)
ret i8*%p
}
define fastcc i8*@_SMLFN6Parser5parseE(i8*inreg%a)#2 gc"smlsharp"personality i32(...)*@sml_personality{
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
store i8*null,i8**%b,align 8
%j=invoke fastcc i8*@_SMLFN14SMLSharpParser5parseE(i8*inreg%h)
to label%G unwind label%k
k:
%l=landingpad{i8*,i8*}
catch i8*null
%m=extractvalue{i8*,i8*}%l,1
%n=bitcast i8*%m to i8**
%o=load i8*,i8**%n,align 8
store i8*%o,i8**%b,align 8
%p=bitcast i8*%o to i8**
%q=load i8*,i8**%p,align 8
%r=load i8*,i8**@_SMLZN14SMLSharpParser5ErrorE,align 8
%s=icmp eq i8*%q,%r
br i1%s,label%t,label%y
t:
%u=getelementptr inbounds i8,i8*%o,i64 16
%v=bitcast i8*%u to i8**
%w=load i8*,i8**%v,align 8
%x=tail call fastcc i8*@_SMLLN6Parser15raiseUserErrorsE_35(i8*inreg%w)
unreachable
y:
%z=call i8*@sml_alloc(i32 inreg 60)#0
%A=getelementptr inbounds i8,i8*%z,i64 -4
%B=bitcast i8*%A to i32*
store i32 1342177336,i32*%B,align 4
%C=getelementptr inbounds i8,i8*%z,i64 56
%D=bitcast i8*%C to i32*
store i32 1,i32*%D,align 4
%E=load i8*,i8**%b,align 8
%F=bitcast i8*%z to i8**
store i8*%E,i8**%F,align 8
call void@sml_raise(i8*inreg%z)#1
unreachable
G:
ret i8*%j
}
define fastcc i32@_SMLFN6Parser5isEOFE(i8*inreg%a)#2 gc"smlsharp"personality i32(...)*@sml_personality{
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
store i8*null,i8**%b,align 8
%j=invoke fastcc i32@_SMLFN14SMLSharpParser5isEOFE(i8*inreg%h)
to label%G unwind label%k
k:
%l=landingpad{i8*,i8*}
catch i8*null
%m=extractvalue{i8*,i8*}%l,1
%n=bitcast i8*%m to i8**
%o=load i8*,i8**%n,align 8
store i8*%o,i8**%b,align 8
%p=bitcast i8*%o to i8**
%q=load i8*,i8**%p,align 8
%r=load i8*,i8**@_SMLZN14SMLSharpParser5ErrorE,align 8
%s=icmp eq i8*%q,%r
br i1%s,label%t,label%y
t:
%u=getelementptr inbounds i8,i8*%o,i64 16
%v=bitcast i8*%u to i8**
%w=load i8*,i8**%v,align 8
store i8*null,i8**%b,align 8
%x=call fastcc i8*@_SMLLN6Parser15raiseUserErrorsE_35(i8*inreg%w)
unreachable
y:
%z=call i8*@sml_alloc(i32 inreg 60)#0
%A=getelementptr inbounds i8,i8*%z,i64 -4
%B=bitcast i8*%A to i32*
store i32 1342177336,i32*%B,align 4
%C=getelementptr inbounds i8,i8*%z,i64 56
%D=bitcast i8*%C to i32*
store i32 1,i32*%D,align 4
%E=load i8*,i8**%b,align 8
%F=bitcast i8*%z to i8**
store i8*%E,i8**%F,align 8
call void@sml_raise(i8*inreg%z)#1
unreachable
G:
ret i32%j
}
define fastcc i8*@_SMLFN6Parser13sourceOfInputE(i8*inreg%a)local_unnamed_addr#2 gc"smlsharp"{
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
%j=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[2x i8*]}>,<{[4x i8],i32,[2x i8*]}>*@_SML_gvar76f5db83044d8678_Parser,i64 0,i32 2,i64 1),align 8
%k=getelementptr inbounds i8,i8*%j,i64 16
%l=bitcast i8*%k to i8*(i8*,i8*)**
%m=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%l,align 8
%n=bitcast i8*%j to i8**
%o=load i8*,i8**%n,align 8
%p=tail call fastcc i8*%m(i8*inreg%o,i8*inreg%h)
ret i8*%p
}
define internal fastcc i8*@_SMLLN6Parser15raiseUserErrorsE_45(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLLN6Parser15raiseUserErrorsE_33(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLN6Parser5parseE_49(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN6Parser5parseE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLN6Parser5isEOFE_50(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i32@_SMLFN6Parser5isEOFE(i8*inreg%b)
%d=tail call i8*@sml_alloc(i32 inreg 4)#0
%e=bitcast i8*%d to i32*
%f=getelementptr inbounds i8,i8*%d,i64 -4
%g=bitcast i8*%f to i32*
store i32 4,i32*%g,align 4
store i32%c,i32*%e,align 4
ret i8*%d
}
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
attributes#4={nounwind uwtable}
attributes#5={noreturn uwtable}
