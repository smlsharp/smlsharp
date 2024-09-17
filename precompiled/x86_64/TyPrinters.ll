@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN3Bug10debugPrintE=external local_unnamed_addr global i8*
@a=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c".\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(void(i8*)*@_SMLFN10TyPrinters9printPathE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN10TyPrinters9printPathE_44 to void(...)*),i32 -2147483647}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(void(i8*)*@_SMLFN10TyPrinters7printTyE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN10TyPrinters7printTyE_45 to void(...)*),i32 -2147483647}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(void(i8*)*@_SMLFN10TyPrinters14printTpVarInfoE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN10TyPrinters14printTpVarInfoE_46 to void(...)*),i32 -2147483647}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(void(i8*)*@_SMLFN10TyPrinters5printE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN10TyPrinters5printE_47 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN10TyPrinters5printE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@e,i64 0,i32 2)to i8*)
@_SMLZN10TyPrinters9printPathE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@b,i64 0,i32 2)to i8*)
@_SMLZN10TyPrinters7printTyE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*)
@_SMLZN10TyPrinters14printTpVarInfoE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@d,i64 0,i32 2)to i8*)
@_SML_ftab1dab015450488842_TyPrinters=external global i8
@f=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i8*@_SMLFN3Bug11prettyPrintE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN5Types22formatWithType__varInfoE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN5Types9format__tyE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare i8*@_SMLFN6String10concatWithE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare void@_SMLFN6TextIO5printE(i8*inreg)local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main1ef93e13728790b1_String()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main3446b7b079949ccf_text_io()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_maineaa0aca8fbe4101a_Bug()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main606b245a3d2b48d6_Types_ppg()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_load1ef93e13728790b1_String(i8*)local_unnamed_addr
declare void@_SML_load3446b7b079949ccf_text_io(i8*)local_unnamed_addr
declare void@_SML_loadeaa0aca8fbe4101a_Bug(i8*)local_unnamed_addr
declare void@_SML_load606b245a3d2b48d6_Types_ppg(i8*)local_unnamed_addr
define private void@_SML_tabb1dab015450488842_TyPrinters()#2{
unreachable
}
define void@_SML_load1dab015450488842_TyPrinters(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@f,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@f,align 1
tail call void@_SML_load1ef93e13728790b1_String(i8*%a)#0
tail call void@_SML_load3446b7b079949ccf_text_io(i8*%a)#0
tail call void@_SML_loadeaa0aca8fbe4101a_Bug(i8*%a)#0
tail call void@_SML_load606b245a3d2b48d6_Types_ppg(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb1dab015450488842_TyPrinters,i8*@_SML_ftab1dab015450488842_TyPrinters,i8*null)#0
ret void
}
define void@_SML_main1dab015450488842_TyPrinters()local_unnamed_addr#1 gc"smlsharp"{
%a=load i8,i8*@f,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@f,align 1
tail call void@_SML_main1ef93e13728790b1_String()#1
tail call void@_SML_main3446b7b079949ccf_text_io()#1
tail call void@_SML_maineaa0aca8fbe4101a_Bug()#1
tail call void@_SML_main606b245a3d2b48d6_Types_ppg()#1
br label%d
}
define fastcc void@_SMLFN10TyPrinters9printPathE(i8*inreg%a)#1 gc"smlsharp"{
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
%g=load i32*,i32**bitcast(i8**@_SMLZN3Bug10debugPrintE to i32**),align 8
%h=load i32,i32*%g,align 4
%i=icmp eq i32%h,0
br i1%i,label%w,label%j
j:
%k=call fastcc i8*@_SMLFN6String10concatWithE(i8*inreg getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@a,i64 0,i32 2,i64 0))
%l=getelementptr inbounds i8,i8*%k,i64 16
%m=bitcast i8*%l to i8*(i8*,i8*)**
%n=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%m,align 8
%o=bitcast i8*%k to i8**
%p=load i8*,i8**%o,align 8
%q=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%r=call fastcc i8*%n(i8*inreg%p,i8*inreg%q)
%s=load i32*,i32**bitcast(i8**@_SMLZN3Bug10debugPrintE to i32**),align 8
%t=load i32,i32*%s,align 4
%u=icmp eq i32%t,0
br i1%u,label%w,label%v
v:
tail call fastcc void@_SMLFN6TextIO5printE(i8*inreg%r)
ret void
w:
ret void
}
define fastcc void@_SMLFN10TyPrinters7printTyE(i8*inreg%a)#1 gc"smlsharp"{
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
%j=load i32*,i32**bitcast(i8**@_SMLZN3Bug10debugPrintE to i32**),align 8
%k=load i32,i32*%j,align 4
%l=icmp eq i32%k,0
br i1%l,label%t,label%m
m:
%n=call fastcc i8*@_SMLFN5Types9format__tyE(i8*inreg%h)
%o=call fastcc i8*@_SMLFN3Bug11prettyPrintE(i8*inreg%n)
%p=load i32*,i32**bitcast(i8**@_SMLZN3Bug10debugPrintE to i32**),align 8
%q=load i32,i32*%p,align 4
%r=icmp eq i32%q,0
br i1%r,label%t,label%s
s:
tail call fastcc void@_SMLFN6TextIO5printE(i8*inreg%o)
ret void
t:
ret void
}
define fastcc void@_SMLFN10TyPrinters14printTpVarInfoE(i8*inreg%a)#1 gc"smlsharp"{
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
%j=load i32*,i32**bitcast(i8**@_SMLZN3Bug10debugPrintE to i32**),align 8
%k=load i32,i32*%j,align 4
%l=icmp eq i32%k,0
br i1%l,label%t,label%m
m:
%n=call fastcc i8*@_SMLFN5Types22formatWithType__varInfoE(i8*inreg%h)
%o=call fastcc i8*@_SMLFN3Bug11prettyPrintE(i8*inreg%n)
%p=load i32*,i32**bitcast(i8**@_SMLZN3Bug10debugPrintE to i32**),align 8
%q=load i32,i32*%p,align 4
%r=icmp eq i32%q,0
br i1%r,label%t,label%s
s:
tail call fastcc void@_SMLFN6TextIO5printE(i8*inreg%o)
ret void
t:
ret void
}
define fastcc void@_SMLFN10TyPrinters5printE(i8*inreg%a)#1 gc"smlsharp"{
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
%g=load i32*,i32**bitcast(i8**@_SMLZN3Bug10debugPrintE to i32**),align 8
%h=load i32,i32*%g,align 4
%i=icmp eq i32%h,0
br i1%i,label%l,label%j
j:
%k=load i8*,i8**%b,align 8
tail call fastcc void@_SMLFN6TextIO5printE(i8*inreg%k)
ret void
l:
ret void
}
define internal fastcc i8*@_SMLLN10TyPrinters9printPathE_44(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLFN10TyPrinters9printPathE(i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLN10TyPrinters7printTyE_45(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLFN10TyPrinters7printTyE(i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLN10TyPrinters14printTpVarInfoE_46(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLFN10TyPrinters14printTpVarInfoE(i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
define internal fastcc i8*@_SMLLN10TyPrinters5printE_47(i8*inreg%a,i8*inreg%b)#1 gc"smlsharp"{
tail call fastcc void@_SMLFN10TyPrinters5printE(i8*inreg%b)
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
