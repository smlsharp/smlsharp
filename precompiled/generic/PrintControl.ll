@_SMLDN12PrintControl10printWidthE_27=private global<{[4x i8],i32,i32}><{[4x i8]zeroinitializer,i32 -1610612732,i32 80}>,align 8
@_SMLDN12PrintControl13printMaxDepthE_28=private global<{[4x i8],i32,i32}><{[4x i8]zeroinitializer,i32 -1610612732,i32 20}>,align 8
@_SMLZN12PrintControl10printWidthE=local_unnamed_addr constant i8*bitcast(i32*getelementptr inbounds(<{[4x i8],i32,i32}>,<{[4x i8],i32,i32}>*@_SMLDN12PrintControl10printWidthE_27,i64 0,i32 2)to i8*)
@_SMLZN12PrintControl13printMaxDepthE=local_unnamed_addr constant i8*bitcast(i32*getelementptr inbounds(<{[4x i8],i32,i32}>,<{[4x i8],i32,i32}>*@_SMLDN12PrintControl13printMaxDepthE_28,i64 0,i32 2)to i8*)
@_SML_ftab3acd53cad8d59eda_PrintControl=external global i8
@a=internal unnamed_addr global i1 false
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
define private void@_SML_tabb3acd53cad8d59eda_PrintControl()#1{
unreachable
}
define void@_SML_load3acd53cad8d59eda_PrintControl(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@a,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@a,align 1
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb3acd53cad8d59eda_PrintControl,i8*@_SML_ftab3acd53cad8d59eda_PrintControl,i8*null)#0
ret void
}
define void@_SML_main3acd53cad8d59eda_PrintControl()local_unnamed_addr#2 gc"smlsharp"{
ret void
}
attributes#0={nounwind}
attributes#1={noreturn nounwind}
attributes#2={nounwind uwtable}
