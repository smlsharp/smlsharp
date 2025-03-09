@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN15BasicFormatters10format__intE=external local_unnamed_addr global i8*
@_SMLZN5Int328toStringE=external local_unnamed_addr global i8*
@a=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i32(i32)*@_SMLFN9DummyTyID8generateE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9DummyTyID8generateE_43 to void(...)*),i32 -2147483647}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i32(i32)*@_SMLFN9DummyTyID4peekE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9DummyTyID4peekE_44 to void(...)*),i32 -2147483647}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i32(i32)*@_SMLFN9DummyTyID4succE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9DummyTyID4succE_45 to void(...)*),i32 -2147483647}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i32(i8*)*@_SMLFN9DummyTyID11isNewerThanE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN9DummyTyID11isNewerThanE_46 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN9DummyTyID8generateE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@a,i64 0,i32 2)to i8*)
@_SMLZN9DummyTyID4peekE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@b,i64 0,i32 2)to i8*)
@_SMLZN9DummyTyID4succE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*)
@_SMLZN9DummyTyID11isNewerThanE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@d,i64 0,i32 2)to i8*)
@_SML_gvarf05fe994141c896f_DummyTyID=private global<{[4x i8],i32,[4x i8*]}><{[4x i8]zeroinitializer,i32 -1342177248,[4x i8*]zeroinitializer}>,align 8
@e=private unnamed_addr global[2x i64][i64 1,i64 sub(i64 ptrtoint(i8**getelementptr inbounds(<{[4x i8],i32,[4x i8*]}>,<{[4x i8],i32,[4x i8*]}>*@_SML_gvarf05fe994141c896f_DummyTyID,i32 0,i32 2,i32 0)to i64),i64 ptrtoint([2x i64]*@e to i64))]
@_SML_ftabf05fe994141c896f_DummyTyID=external global i8
@f=private unnamed_addr global i8 0
@g=internal unnamed_addr global i32 0,align 8
@_SMLZN9DummyTyID9format__idE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[4x i8*]}>,<{[4x i8],i32,[4x i8*]}>*@_SML_gvarf05fe994141c896f_DummyTyID,i32 0,i32 2,i32 0)
@_SMLZN9DummyTyID11format__snapE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[4x i8*]}>,<{[4x i8],i32,[4x i8*]}>*@_SML_gvarf05fe994141c896f_DummyTyID,i32 0,i32 2,i32 1)
@_SMLZN9DummyTyID8toStringE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[4x i8*]}>,<{[4x i8],i32,[4x i8*]}>*@_SML_gvarf05fe994141c896f_DummyTyID,i32 0,i32 2,i32 2)
@_SMLZN9DummyTyID12snapToStringE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[4x i8*]}>,<{[4x i8],i32,[4x i8*]}>*@_SML_gvarf05fe994141c896f_DummyTyID,i32 0,i32 2,i32 3)
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_end()local_unnamed_addr#0
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_start(i8*inreg)local_unnamed_addr#0
declare void@sml_write(i8*inreg,i8**inreg,i8*inreg)local_unnamed_addr#0
declare void@_SML_main5148a836b3728be9_Int32()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_main6ad4d8e473c26a9c_BasicFormatters()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_load5148a836b3728be9_Int32(i8*)local_unnamed_addr
declare void@_SML_load6ad4d8e473c26a9c_BasicFormatters(i8*)local_unnamed_addr
define private void@_SML_tabbf05fe994141c896f_DummyTyID()#2{
unreachable
}
define void@_SML_loadf05fe994141c896f_DummyTyID(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@f,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@f,align 1
tail call void@_SML_load5148a836b3728be9_Int32(i8*%a)#0
tail call void@_SML_load6ad4d8e473c26a9c_BasicFormatters(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbf05fe994141c896f_DummyTyID,i8*@_SML_ftabf05fe994141c896f_DummyTyID,i8*bitcast([2x i64]*@e to i8*))#0
ret void
}
define void@_SML_mainf05fe994141c896f_DummyTyID()local_unnamed_addr#1 gc"smlsharp"{
%a=alloca[3x i8*],align 8
%b=load i8,i8*@f,align 1
%c=and i8%b,2
%d=icmp eq i8%c,0
br i1%d,label%f,label%e
e:
ret void
f:
store i8 3,i8*@f,align 1
tail call void@_SML_main5148a836b3728be9_Int32()#1
tail call void@_SML_main6ad4d8e473c26a9c_BasicFormatters()#1
%g=bitcast[3x i8*]*%a to i8*
call void@sml_start(i8*inreg%g)#0
%h=load i8*,i8**@_SMLZN15BasicFormatters10format__intE,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[4x i8*]}>,<{[4x i8],i32,[4x i8*]}>*@_SML_gvarf05fe994141c896f_DummyTyID,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[4x i8*]}>,<{[4x i8],i32,[4x i8*]}>*@_SML_gvarf05fe994141c896f_DummyTyID,i64 0,i32 2,i64 0),i8*inreg%h)#0
%i=load i8*,i8**@_SMLZN15BasicFormatters10format__intE,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[4x i8*]}>,<{[4x i8],i32,[4x i8*]}>*@_SML_gvarf05fe994141c896f_DummyTyID,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[4x i8*]}>,<{[4x i8],i32,[4x i8*]}>*@_SML_gvarf05fe994141c896f_DummyTyID,i64 0,i32 2,i64 1),i8*inreg%i)#0
%j=load i8*,i8**@_SMLZN5Int328toStringE,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[4x i8*]}>,<{[4x i8],i32,[4x i8*]}>*@_SML_gvarf05fe994141c896f_DummyTyID,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[4x i8*]}>,<{[4x i8],i32,[4x i8*]}>*@_SML_gvarf05fe994141c896f_DummyTyID,i64 0,i32 2,i64 2),i8*inreg%j)#0
%k=load i8*,i8**@_SMLZN5Int328toStringE,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[4x i8*]}>,<{[4x i8],i32,[4x i8*]}>*@_SML_gvarf05fe994141c896f_DummyTyID,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[4x i8*]}>,<{[4x i8],i32,[4x i8*]}>*@_SML_gvarf05fe994141c896f_DummyTyID,i64 0,i32 2,i64 3),i8*inreg%k)#0
call void@sml_end()#0
ret void
}
define fastcc i32@_SMLFN9DummyTyID8generateE(i32 inreg%a)#3 gc"smlsharp"{
%b=load i32,i32*@g,align 8
%c=add nsw i32%b,1
store i32%c,i32*@g,align 8
ret i32%b
}
define fastcc i32@_SMLFN9DummyTyID4peekE(i32 inreg%a)#3 gc"smlsharp"{
%b=load i32,i32*@g,align 8
ret i32%b
}
define fastcc i32@_SMLFN9DummyTyID4succE(i32 inreg%a)#3 gc"smlsharp"{
%b=add nsw i32%a,1
ret i32%b
}
define fastcc i32@_SMLFN9DummyTyID11isNewerThanE(i8*inreg%a)#3 gc"smlsharp"{
%b=bitcast i8*%a to i32*
%c=load i32,i32*%b,align 4
%d=getelementptr inbounds i8,i8*%a,i64 4
%e=bitcast i8*%d to i32*
%f=load i32,i32*%e,align 4
%g=icmp sge i32%c,%f
%h=zext i1%g to i32
ret i32%h
}
define fastcc i8*@_SMLFN9DummyTyID9format__idE(i32 inreg%a)local_unnamed_addr#1 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[4x i8*]}>,<{[4x i8],i32,[4x i8*]}>*@_SML_gvarf05fe994141c896f_DummyTyID,i64 0,i32 2,i64 0),align 8
%h=getelementptr inbounds i8,i8*%g,i64 16
%i=bitcast i8*%h to i8*(i8*,i8*)**
%j=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%i,align 8
%k=bitcast i8*%g to i8**
%l=load i8*,i8**%k,align 8
store i8*%l,i8**%b,align 8
%m=call i8*@sml_alloc(i32 inreg 4)#0
%n=bitcast i8*%m to i32*
%o=getelementptr inbounds i8,i8*%m,i64 -4
%p=bitcast i8*%o to i32*
store i32 4,i32*%p,align 4
store i32%a,i32*%n,align 4
%q=load i8*,i8**%b,align 8
%r=tail call fastcc i8*%j(i8*inreg%q,i8*inreg%m)
ret i8*%r
}
define fastcc i8*@_SMLFN9DummyTyID11format__snapE(i32 inreg%a)local_unnamed_addr#1 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[4x i8*]}>,<{[4x i8],i32,[4x i8*]}>*@_SML_gvarf05fe994141c896f_DummyTyID,i64 0,i32 2,i64 1),align 8
%h=getelementptr inbounds i8,i8*%g,i64 16
%i=bitcast i8*%h to i8*(i8*,i8*)**
%j=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%i,align 8
%k=bitcast i8*%g to i8**
%l=load i8*,i8**%k,align 8
store i8*%l,i8**%b,align 8
%m=call i8*@sml_alloc(i32 inreg 4)#0
%n=bitcast i8*%m to i32*
%o=getelementptr inbounds i8,i8*%m,i64 -4
%p=bitcast i8*%o to i32*
store i32 4,i32*%p,align 4
store i32%a,i32*%n,align 4
%q=load i8*,i8**%b,align 8
%r=tail call fastcc i8*%j(i8*inreg%q,i8*inreg%m)
ret i8*%r
}
define fastcc i8*@_SMLFN9DummyTyID8toStringE(i32 inreg%a)local_unnamed_addr#1 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[4x i8*]}>,<{[4x i8],i32,[4x i8*]}>*@_SML_gvarf05fe994141c896f_DummyTyID,i64 0,i32 2,i64 2),align 8
%h=getelementptr inbounds i8,i8*%g,i64 16
%i=bitcast i8*%h to i8*(i8*,i8*)**
%j=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%i,align 8
%k=bitcast i8*%g to i8**
%l=load i8*,i8**%k,align 8
store i8*%l,i8**%b,align 8
%m=call i8*@sml_alloc(i32 inreg 4)#0
%n=bitcast i8*%m to i32*
%o=getelementptr inbounds i8,i8*%m,i64 -4
%p=bitcast i8*%o to i32*
store i32 4,i32*%p,align 4
store i32%a,i32*%n,align 4
%q=load i8*,i8**%b,align 8
%r=tail call fastcc i8*%j(i8*inreg%q,i8*inreg%m)
ret i8*%r
}
define fastcc i8*@_SMLFN9DummyTyID12snapToStringE(i32 inreg%a)local_unnamed_addr#1 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[4x i8*]}>,<{[4x i8],i32,[4x i8*]}>*@_SML_gvarf05fe994141c896f_DummyTyID,i64 0,i32 2,i64 3),align 8
%h=getelementptr inbounds i8,i8*%g,i64 16
%i=bitcast i8*%h to i8*(i8*,i8*)**
%j=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%i,align 8
%k=bitcast i8*%g to i8**
%l=load i8*,i8**%k,align 8
store i8*%l,i8**%b,align 8
%m=call i8*@sml_alloc(i32 inreg 4)#0
%n=bitcast i8*%m to i32*
%o=getelementptr inbounds i8,i8*%m,i64 -4
%p=bitcast i8*%o to i32*
store i32 4,i32*%p,align 4
store i32%a,i32*%n,align 4
%q=load i8*,i8**%b,align 8
%r=tail call fastcc i8*%j(i8*inreg%q,i8*inreg%m)
ret i8*%r
}
define internal fastcc i8*@_SMLLLN9DummyTyID8generateE_43(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=load i32,i32*@g,align 8
%d=add nsw i32%c,1
store i32%d,i32*@g,align 8
%e=tail call i8*@sml_alloc(i32 inreg 4)#0
%f=bitcast i8*%e to i32*
%g=getelementptr inbounds i8,i8*%e,i64 -4
%h=bitcast i8*%g to i32*
store i32 4,i32*%h,align 4
store i32%c,i32*%f,align 4
ret i8*%e
}
define internal fastcc i8*@_SMLLLN9DummyTyID4peekE_44(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=load i32,i32*@g,align 8
%d=tail call i8*@sml_alloc(i32 inreg 4)#0
%e=bitcast i8*%d to i32*
%f=getelementptr inbounds i8,i8*%d,i64 -4
%g=bitcast i8*%f to i32*
store i32 4,i32*%g,align 4
store i32%c,i32*%e,align 4
ret i8*%d
}
define internal fastcc i8*@_SMLLLN9DummyTyID4succE_45(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=add nsw i32%d,1
%f=tail call i8*@sml_alloc(i32 inreg 4)#0
%g=bitcast i8*%f to i32*
%h=getelementptr inbounds i8,i8*%f,i64 -4
%i=bitcast i8*%h to i32*
store i32 4,i32*%i,align 4
store i32%e,i32*%g,align 4
ret i8*%f
}
define internal fastcc i8*@_SMLLLN9DummyTyID11isNewerThanE_46(i8*inreg%a,i8*inreg%b)#3 gc"smlsharp"{
%c=bitcast i8*%b to i32*
%d=load i32,i32*%c,align 4
%e=getelementptr inbounds i8,i8*%b,i64 4
%f=bitcast i8*%e to i32*
%g=load i32,i32*%f,align 4
%h=icmp sge i32%d,%g
%i=zext i1%h to i32
%j=tail call i8*@sml_alloc(i32 inreg 4)#0
%k=bitcast i8*%j to i32*
%l=getelementptr inbounds i8,i8*%j,i64 -4
%m=bitcast i8*%l to i32*
store i32 4,i32*%m,align 4
store i32%i,i32*%k,align 4
ret i8*%j
}
attributes#0={nounwind}
attributes#1={uwtable}
attributes#2={noreturn nounwind}
attributes#3={nounwind uwtable}
