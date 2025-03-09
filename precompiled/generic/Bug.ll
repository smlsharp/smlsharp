@sml_check_flag=external local_unnamed_addr global i32
@a=private unnamed_addr constant<{[4x i8],i32,[8x i8]}><{[4x i8]zeroinitializer,i32 -2147483640,[8x i8]c"Bug.Bug\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[8x i8]}>,<{[4x i8],i32,[8x i8]}>*@a,i32 0,i32 0,i32 0),i32 8),i32 16,[4x i8]zeroinitializer,i32 1}>,align 8
@_SMLDL33=private constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@b,i32 0,i32 0,i32 0),i32 8)}>,align 8
@_SMLDL34=private global<{[4x i8],i32,i32}><{[4x i8]zeroinitializer,i32 -1610612732,i32 0}>,align 8
@_SMLDL35=private global<{[4x i8],i32,i32}><{[4x i8]zeroinitializer,i32 -1610612732,i32 0}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN3Bug11prettyPrintE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN3Bug11prettyPrintE_42 to void(...)*),i32 -2147483647}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(void(i8*)*@_SMLFN3Bug10printErrorE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN3Bug10printErrorE_43 to void(...)*),i32 -2147483647}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(void(i8*)*@_SMLFN3Bug12printMessageE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN3Bug12printMessageE_44 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN3Bug3BugE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL33,i64 0,i32 2)to i8*)
@_SMLZN3Bug10debugPrintE=local_unnamed_addr constant i8*bitcast(i32*getelementptr inbounds(<{[4x i8],i32,i32}>,<{[4x i8],i32,i32}>*@_SMLDL34,i64 0,i32 2)to i8*)
@_SMLZN3Bug9printInfoE=local_unnamed_addr constant i8*bitcast(i32*getelementptr inbounds(<{[4x i8],i32,i32}>,<{[4x i8],i32,i32}>*@_SMLDL35,i64 0,i32 2)to i8*)
@_SMLZN3Bug11prettyPrintE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*)
@_SMLZN3Bug10printErrorE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@d,i64 0,i32 2)to i8*)
@_SMLZN3Bug12printMessageE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@e,i64 0,i32 2)to i8*)
@_SML_ftabeaa0aca8fbe4101a_Bug=external global i8
@f=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@_SMLFN6TextIO5printE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN9SMLFormat11prettyPrintE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main3446b7b079949ccf_text_io()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_maindcdf3bbf6cbeefdd_SMLFormat()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_load3446b7b079949ccf_text_io(i8*)local_unnamed_addr
declare void@_SML_loaddcdf3bbf6cbeefdd_SMLFormat(i8*)local_unnamed_addr
define private void@_SML_tabbeaa0aca8fbe4101a_Bug()#2{
unreachable
}
define void@_SML_loadeaa0aca8fbe4101a_Bug(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@f,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@f,align 1
tail call void@_SML_load3446b7b079949ccf_text_io(i8*%a)#0
tail call void@_SML_loaddcdf3bbf6cbeefdd_SMLFormat(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbeaa0aca8fbe4101a_Bug,i8*@_SML_ftabeaa0aca8fbe4101a_Bug,i8*null)#0
ret void
}
define void@_SML_maineaa0aca8fbe4101a_Bug()local_unnamed_addr#1 gc"smlsharp"{
%a=load i8,i8*@f,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@f,align 1
tail call void@_SML_main3446b7b079949ccf_text_io()#1
tail call void@_SML_maindcdf3bbf6cbeefdd_SMLFormat()#1
br label%d
}
define fastcc i8*@_SMLFN3Bug11prettyPrintE(i8*inreg%a)#1 gc"smlsharp"{
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
%g=call fastcc i8*@_SMLFN9SMLFormat11prettyPrintE(i8*inreg null)
%h=getelementptr inbounds i8,i8*%g,i64 16
%i=bitcast i8*%h to i8*(i8*,i8*)**
%j=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%i,align 8
%k=bitcast i8*%g to i8**
%l=load i8*,i8**%k,align 8
%m=load i8*,i8**%b,align 8
%n=tail call fastcc i8*%j(i8*inreg%l,i8*inreg%m)
ret i8*%n
}
define fastcc void@_SMLFN3Bug10printErrorE(i8*inreg%a)#1 gc"smlsharp"{
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
%g=load i32,i32*getelementptr inbounds(<{[4x i8],i32,i32}>,<{[4x i8],i32,i32}>*@_SMLDL34,i64 0,i32 2),align 8
%h=icmp eq i32%g,0
br i1%h,label%k,label%i
i:
%j=load i8*,i8**%b,align 8
tail call fastcc void@_SMLFN6TextIO5printE(i8*inreg%j)
ret void
k:
ret void
}
define fastcc void@_SMLFN3Bug12printMessageE(i8*inreg%a)#1 gc"smlsharp"{
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
%g=load i32,i32*getelementptr inbounds(<{[4x i8],i32,i32}>,<{[4x i8],i32,i32}>*@_SMLDL35,i64 0,i32 2),align 8
%h=icmp eq i32%g,0
br i1%h,label%k,label%i
i:
%j=load i8*,i8**%b,align 8
tail call fastcc void@_SMLFN6TextIO5printE(i8*inreg%j)
ret void
k:
ret void
}
define internal fastcc i8*@_SMLLLN3Bug11prettyPrintE_42(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN3Bug11prettyPrintE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN3Bug10printErrorE_43(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLFN3Bug10printErrorE(i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLLN3Bug12printMessageE_44(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLFN3Bug12printMessageE(i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
attributes#0={nounwind}
attributes#1={uwtable}
attributes#2={noreturn nounwind}
