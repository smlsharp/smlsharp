@a=private unnamed_addr constant<{[4x i8],i32,[1x i8]}><{[4x i8]zeroinitializer,i32 -2147483647,[1x i8]zeroinitializer}>,align 8
@_SMLDN19SMLSharp__SQL__Config6DLLEXTE_28=private global<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1342177272,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[1x i8]}>,<{[4x i8],i32,[1x i8]}>*@a,i32 0,i32 0,i32 0),i32 8)}>,align 8
@_SMLZN19SMLSharp__SQL__Config6DLLEXTE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN19SMLSharp__SQL__Config6DLLEXTE_28,i64 0,i32 2)to i8*)
@b=private unnamed_addr global[2x i64][i64 1,i64 sub(i64 ptrtoint(i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDN19SMLSharp__SQL__Config6DLLEXTE_28,i32 0,i32 0,i32 0),i32 8)to i64),i64 ptrtoint([2x i64]*@b to i64))]
@_SML_ftabfb23865721a0c043_SQLConfig=external global i8
@c=internal unnamed_addr global i1 false
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
define private void@_SML_tabbfb23865721a0c043_SQLConfig()#1{
unreachable
}
define void@_SML_loadfb23865721a0c043_SQLConfig(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@c,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@c,align 1
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbfb23865721a0c043_SQLConfig,i8*@_SML_ftabfb23865721a0c043_SQLConfig,i8*bitcast([2x i64]*@b to i8*))#0
ret void
}
define void@_SML_mainfb23865721a0c043_SQLConfig()local_unnamed_addr#2 gc"smlsharp"{
ret void
}
attributes#0={nounwind}
attributes#1={noreturn nounwind}
attributes#2={nounwind uwtable}
