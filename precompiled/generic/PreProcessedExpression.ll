@a=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i32(i8*)*@_SMLFN22PreProcessedExpression12isHigherThanE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN22PreProcessedExpression12isHigherThanE_32 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN22PreProcessedExpression12isHigherThanE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*)
@_SML_ftabf2ccb98f82def81c_PreProcessedExpression=external global i8
@b=internal unnamed_addr global i1 false
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
define private void@_SML_tabbf2ccb98f82def81c_PreProcessedExpression()#1{
unreachable
}
define void@_SML_loadf2ccb98f82def81c_PreProcessedExpression(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@b,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@b,align 1
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbf2ccb98f82def81c_PreProcessedExpression,i8*@_SML_ftabf2ccb98f82def81c_PreProcessedExpression,i8*null)#0
ret void
}
define void@_SML_mainf2ccb98f82def81c_PreProcessedExpression()local_unnamed_addr#2 gc"smlsharp"{
ret void
}
define fastcc i32@_SMLFN22PreProcessedExpression12isHigherThanE(i8*inreg%a)#2 gc"smlsharp"{
%b=bitcast i8*%a to i8**
%c=load i8*,i8**%b,align 8
%d=icmp eq i8*%c,null
%e=getelementptr inbounds i8,i8*%a,i64 8
%f=bitcast i8*%e to i8**
%g=load i8*,i8**%f,align 8
%h=icmp eq i8*%g,null
br i1%d,label%i,label%l
i:
br i1%h,label%t,label%j
j:
%k=phi i32[0,%i],[1,%t]
ret i32%k
l:
br i1%h,label%t,label%m
m:
%n=bitcast i8*%c to i32*
%o=load i32,i32*%n,align 4
%p=bitcast i8*%g to i32*
%q=load i32,i32*%p,align 4
%r=icmp slt i32%o,%q
%s=zext i1%r to i32
ret i32%s
t:
br label%j
}
define internal fastcc i8*@_SMLLN22PreProcessedExpression12isHigherThanE_32(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i32@_SMLFN22PreProcessedExpression12isHigherThanE(i8*inreg%b)
%d=tail call i8*@sml_alloc(i32 inreg 4)#0
%e=bitcast i8*%d to i32*
%f=getelementptr inbounds i8,i8*%d,i64 -4
%g=bitcast i8*%f to i32*
store i32 4,i32*%g,align 4
store i32%c,i32*%e,align 4
ret i8*%d
}
attributes#0={nounwind}
attributes#1={noreturn nounwind}
attributes#2={nounwind uwtable}
