@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN5GenID5toIntE=external local_unnamed_addr global i8*
@_SMLZN5GenID7compareE=external local_unnamed_addr global i8*
@_SMLZN5GenID8generateE=external local_unnamed_addr global i8*
@_SMLZN5GenID8toStringE=external local_unnamed_addr global i8*
@_SMLZN5GenID9format__idE=external local_unnamed_addr global i8*
@_SML_gvarcf2656e90c9ab770_ExistTyID=private global<{[4x i8],i32,[5x i8*]}><{[4x i8]zeroinitializer,i32 -1342177240,[5x i8*]zeroinitializer}>,align 8
@a=private unnamed_addr global[2x i64][i64 1,i64 sub(i64 ptrtoint(i8**getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i32 0,i32 2,i32 0)to i64),i64 ptrtoint([2x i64]*@a to i64))]
@_SML_ftabcf2656e90c9ab770_ExistTyID=external global i8
@b=private unnamed_addr global i8 0
@_SMLZN9ExistTyID8generateE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i32 0,i32 2,i32 0)
@_SMLZN9ExistTyID9format__idE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i32 0,i32 2,i32 1)
@_SMLZN9ExistTyID8toStringE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i32 0,i32 2,i32 2)
@_SMLZN9ExistTyID5toIntE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i32 0,i32 2,i32 3)
@_SMLZN9ExistTyID7compareE=alias i8*,getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i32 0,i32 2,i32 4)
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_end()local_unnamed_addr#0
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_start(i8*inreg)local_unnamed_addr#0
declare void@sml_write(i8*inreg,i8**inreg,i8*inreg)local_unnamed_addr#0
declare void@_SML_maine34408f7185a4f2d_GenIDFun()local_unnamed_addr#1 gc"smlsharp"
declare void@_SML_loade34408f7185a4f2d_GenIDFun(i8*)local_unnamed_addr
define private void@_SML_tabbcf2656e90c9ab770_ExistTyID()#2{
unreachable
}
define void@_SML_loadcf2656e90c9ab770_ExistTyID(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@b,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@b,align 1
tail call void@_SML_loade34408f7185a4f2d_GenIDFun(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabbcf2656e90c9ab770_ExistTyID,i8*@_SML_ftabcf2656e90c9ab770_ExistTyID,i8*bitcast([2x i64]*@a to i8*))#0
ret void
}
define void@_SML_maincf2656e90c9ab770_ExistTyID()local_unnamed_addr#1 gc"smlsharp"{
%a=alloca[3x i8*],align 8
%b=load i8,i8*@b,align 1
%c=and i8%b,2
%d=icmp eq i8%c,0
br i1%d,label%f,label%e
e:
ret void
f:
store i8 3,i8*@b,align 1
tail call void@_SML_maine34408f7185a4f2d_GenIDFun()#1
%g=bitcast[3x i8*]*%a to i8*
call void@sml_start(i8*inreg%g)#0
%h=load i8*,i8**@_SMLZN5GenID8generateE,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i64 0,i32 2,i64 0),i8*inreg%h)#0
%i=load i8*,i8**@_SMLZN5GenID9format__idE,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i64 0,i32 2,i64 1),i8*inreg%i)#0
%j=load i8*,i8**@_SMLZN5GenID8toStringE,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i64 0,i32 2,i64 2),i8*inreg%j)#0
%k=load i8*,i8**@_SMLZN5GenID5toIntE,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i64 0,i32 2,i64 3),i8*inreg%k)#0
%l=load i8*,i8**@_SMLZN5GenID7compareE,align 8
call void@sml_write(i8*inreg bitcast(i8**getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i64 0,i32 2,i64 0)to i8*),i8**inreg getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i64 0,i32 2,i64 4),i8*inreg%l)#0
call void@sml_end()#0
ret void
}
define fastcc i32@_SMLFN9ExistTyID8generateE(i32 inreg%a)local_unnamed_addr#1 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i64 0,i32 2,i64 0),align 8
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
store i8*null,i8**%b,align 8
%r=call fastcc i8*%j(i8*inreg%q,i8*inreg%m)
%s=bitcast i8*%r to i32*
%t=load i32,i32*%s,align 4
ret i32%t
}
define fastcc i8*@_SMLFN9ExistTyID9format__idE(i32 inreg%a)local_unnamed_addr#1 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i64 0,i32 2,i64 1),align 8
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
define fastcc i8*@_SMLFN9ExistTyID8toStringE(i32 inreg%a)local_unnamed_addr#1 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i64 0,i32 2,i64 2),align 8
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
define fastcc i32@_SMLFN9ExistTyID5toIntE(i32 inreg%a)local_unnamed_addr#1 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
%c=load atomic i32,i32*@sml_check_flag unordered,align 4
%d=icmp eq i32%c,0
br i1%d,label%f,label%e
e:
call void@sml_check(i32 inreg%c)
br label%f
f:
%g=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i64 0,i32 2,i64 3),align 8
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
store i8*null,i8**%b,align 8
%r=call fastcc i8*%j(i8*inreg%q,i8*inreg%m)
%s=bitcast i8*%r to i32*
%t=load i32,i32*%s,align 4
ret i32%t
}
define fastcc i32@_SMLFN9ExistTyID7compareE(i8*inreg%a)local_unnamed_addr#1 gc"smlsharp"{
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
%j=load i8*,i8**getelementptr inbounds(<{[4x i8],i32,[5x i8*]}>,<{[4x i8],i32,[5x i8*]}>*@_SML_gvarcf2656e90c9ab770_ExistTyID,i64 0,i32 2,i64 4),align 8
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
