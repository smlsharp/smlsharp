@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN6String7compareE=external local_unnamed_addr global i8*
@_SML_gvare3dfe04e82f4d0e7_SOrd=private global<{[4x i8],i32,[1x i8*]}><{[4x i8]zeroinitializer,i32 -1342177272,[1x i8*]zeroinitializer}>,align 8
@a=private unnamed_addr global[2x i64][i64 1,i64 sub(i64 ptrtoint(i8**getelementptr inbounds(<{[4x i8],i32,[1x i8*]}>,<{[4x i8],i32,[1x i8*]}>*@_SML_gvare3dfe04e82f4d0e7_SOrd,i32 0,i32 2,i32 0)to i64),i64 ptrtoint([2x i64]*@a to i64))]
@_SML_ftabe3dfe04e82f4d0e7_SOrd=external global i8
@b=private unnamed_addr global i8 0
@_SMLZN4SOrd7compareE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[1x i8*]}>,<{[4x i8],i32,[1x i8*]}>*@_SML_gvare3dfe04e82f4d0e7_SOrd,i32 0,i32 2,i32 0)
declare void@llvm.gcroot(i8**,i8*)#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_end()local_unnamed_addr#0
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_start(i8*inreg)local_unnamed_addr#0
declare void@sml_write(i8*inreg,i8**inreg,i8*inreg)local_unnamed_addr#0
declare void@_SML_main1ef93e13728790b1_String()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_load1ef93e13728790b1_String(i8*)local_unnamed_addr
define private void@_SML_tabbe3dfe04e82f4d0e7_SOrd()#2{
unreachable
}
define void@_SML_loade3dfe04e82f4d0e7_SOrd(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@b,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@b,align 1
tail call void@_SML_load1ef93e13728790b1_String(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbe3dfe04e82f4d0e7_SOrd,i8*@_SML_ftabe3dfe04e82f4d0e7_SOrd,i8*bitcast([2x i64]*@a to i8*))#0
ret void
}
define void@_SML_maine3dfe04e82f4d0e7_SOrd()local_unnamed_addr#1 gc"smlsharp"{
%a=alloca[3x i8*],align 8
%b=load i8,i8*@b,align 1
%c=and i8%b,2
%d=icmp eq i8%c,0
br i1%d,label%f,label%e
e:
ret void
f:
store i8 3,i8*@b,align 1
tail call void@_SML_main1ef93e13728790b1_String()#1
%g=bitcast[3x i8*]*%a to i8*
call void@sml_start(i8*inreg%g)#0
%h=load i8*,i8**@_SMLZN6String7compareE,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[1x i8*]}>,<{[4x i8],i32,[1x i8*]}>*@_SML_gvare3dfe04e82f4d0e7_SOrd,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[1x i8*]}>,<{[4x i8],i32,[1x i8*]}>*@_SML_gvare3dfe04e82f4d0e7_SOrd,i64 0,i32 2,i64 0),i8*inreg%h)#0
call void@sml_end()#0
ret void
}
define fastcc i32@_SMLFN4SOrd7compareE(i8*inreg%a)local_unnamed_addr#1 gc"smlsharp"{
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
%j=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[1x i8*]}>,<{[4x i8],i32,[1x i8*]}>*@_SML_gvare3dfe04e82f4d0e7_SOrd,i64 0,i32 2,i64 0),align 8
%k=getelementptr inbounds i8,i8*%j,i64 16
%l=bitcast i8*%k to i8*(i8*,i8*)**
%m=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%l,align 8
%n=bitcast i8*%j to i8**
%o=load i8*,i8**%n,align 8
%p=call fastcc i8*%m(i8*inreg%o,i8*inreg%h)
%q=bitcast i8*%p to i32*
%r=load i32,i32*%q,align 4
ret i32%r
}
attributes#0={nounwind}
attributes#1={uwtable}
attributes#2={noreturn nounwind}
