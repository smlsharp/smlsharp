@sml_check_flag=external local_unnamed_addr global i32
@_SMLZN9Substring4getcE=external local_unnamed_addr global i8*
@a=private unnamed_addr constant<{[4x i8],i32,[37x i8]}><{[4x i8]zeroinitializer,i32 -2147483611,[37x i8]c"SMLSharp_SQL_KeyValuePair.ParseError\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[37x i8]}>,<{[4x i8],i32,[37x i8]}>*@a,i32 0,i32 0,i32 0),i32 8),i32 0,[4x i8]zeroinitializer,i32 1}>,align 8
@_SMLDL88=private constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@b,i32 0,i32 0,i32 0),i32 8)}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,[43x i8]}><{[4x i8]zeroinitializer,i32 -2147483605,[43x i8]c"src/sql/main/KeyValuePair.sml:126.19(3258)\00"}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i8*,i8*,i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL88,i32 0,i32 0,i32 0),i32 8),i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[43x i8]}>,<{[4x i8],i32,[43x i8]}>*@c,i32 0,i32 0,i32 0),i32 8),i32 3}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN25SMLSharp__SQL__KeyValuePair5parseE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair5parseE_141 to void(...)*),i32 -2147483647}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN25SMLSharp__SQL__KeyValuePair4findE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair4findE_143 to void(...)*),i32 -2147483647}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN25SMLSharp__SQL__KeyValuePair10findExceptE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair10findExceptE_146 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN25SMLSharp__SQL__KeyValuePair10ParseErrorE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL88,i64 0,i32 2)to i8*)
@_SMLZN25SMLSharp__SQL__KeyValuePair5parseE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@e,i64 0,i32 2)to i8*)
@_SMLZN25SMLSharp__SQL__KeyValuePair4findE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@f,i64 0,i32 2)to i8*)
@_SMLZN25SMLSharp__SQL__KeyValuePair10findExceptE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@g,i64 0,i32 2)to i8*)
@_SML_ftab01462d884291b3a4_KeyValuePair=external global i8
@h=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare i32@sml_obj_equal(i8*inreg,i8*inreg)local_unnamed_addr#0
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare i8*@_SMLFN10CharVector8fromListE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i32@_SMLFN4Bool3notE(i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i32@_SMLFN4Char10isAlphaNumE(i8 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i32@_SMLFN4Char7isSpaceE(i8 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List4findE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN4List6existsE(i32 inreg,i32 inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN9Substring4fullE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main145db56e6796da5b_Substring()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maindaa180c1799f3810_Bool()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maince7036f3433e1102_Char()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_mainadbb5309e852b68c_CharVector()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main03d87556ec7f64b2_List()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load145db56e6796da5b_Substring(i8*)local_unnamed_addr
declare void@_SML_loaddaa180c1799f3810_Bool(i8*)local_unnamed_addr
declare void@_SML_loadce7036f3433e1102_Char(i8*)local_unnamed_addr
declare void@_SML_loadadbb5309e852b68c_CharVector(i8*)local_unnamed_addr
declare void@_SML_load03d87556ec7f64b2_List(i8*)local_unnamed_addr
define private void@_SML_tabb01462d884291b3a4_KeyValuePair()#3{
unreachable
}
define void@_SML_load01462d884291b3a4_KeyValuePair(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@h,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@h,align 1
tail call void@_SML_load145db56e6796da5b_Substring(i8*%a)#0
tail call void@_SML_loaddaa180c1799f3810_Bool(i8*%a)#0
tail call void@_SML_loadce7036f3433e1102_Char(i8*%a)#0
tail call void@_SML_loadadbb5309e852b68c_CharVector(i8*%a)#0
tail call void@_SML_load03d87556ec7f64b2_List(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb01462d884291b3a4_KeyValuePair,i8*@_SML_ftab01462d884291b3a4_KeyValuePair,i8*null)#0
ret void
}
define void@_SML_main01462d884291b3a4_KeyValuePair()local_unnamed_addr#2 gc"smlsharp"{
%a=load i8,i8*@h,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@h,align 1
tail call void@_SML_main145db56e6796da5b_Substring()#2
tail call void@_SML_maindaa180c1799f3810_Bool()#2
tail call void@_SML_maince7036f3433e1102_Char()#2
tail call void@_SML_mainadbb5309e852b68c_CharVector()#2
tail call void@_SML_main03d87556ec7f64b2_List()#2
br label%d
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair10scanRepeatE_89(i8*inreg%a,i8*inreg%b,i8*inreg%c)#2 gc"smlsharp"{
p:
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
store i8*%a,i8**%g,align 8
store i8*%b,i8**%e,align 8
store i8*%c,i8**%d,align 8
%h=load atomic i32,i32*@sml_check_flag unordered,align 4
%i=icmp eq i32%h,0
br i1%i,label%n,label%j
j:
call void@sml_check(i32 inreg%h)
%k=load i8*,i8**%d,align 8
%l=load i8*,i8**%e,align 8
%m=load i8*,i8**%g,align 8
br label%n
n:
%o=phi i8*[%m,%j],[%a,%p]
%q=phi i8*[%l,%j],[%b,%p]
%r=phi i8*[%k,%j],[%c,%p]
%s=getelementptr inbounds i8,i8*%o,i64 4
%t=bitcast i8*%s to i32*
%u=load i32,i32*%t,align 4
%v=add i32%u,-1
%w=sub i32 0,%u
%x=and i32%v,%w
%y=add i32%u,7
%z=add i32%y,%x
%A=and i32%z,-8
%B=add i32%A,15
%C=and i32%B,-8
%D=lshr i32%z,3
%E=lshr i32%x,3
%F=sub nsw i32%D,%E
%G=shl i32 1,%F
%H=bitcast i8*%o to i32*
%I=load i32,i32*%H,align 4
%J=or i32%G,%I
%K=or i32%C,4
%L=getelementptr inbounds i8,i8*%q,i64 16
%M=bitcast i8*%L to i8*(i8*,i8*)**
%N=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%M,align 8
%O=bitcast i8*%q to i8**
%P=load i8*,i8**%O,align 8
%Q=call fastcc i8*%N(i8*inreg%P,i8*inreg%r)
%R=icmp eq i8*%Q,null
br i1%R,label%S,label%ac
S:
store i8*null,i8**%e,align 8
store i8*null,i8**%g,align 8
%T=call i8*@sml_alloc(i32 inreg 20)#0
%U=getelementptr inbounds i8,i8*%T,i64 -4
%V=bitcast i8*%U to i32*
store i32 1342177296,i32*%V,align 4
%W=bitcast i8*%T to i8**
store i8*null,i8**%W,align 8
%X=load i8*,i8**%d,align 8
%Y=getelementptr inbounds i8,i8*%T,i64 8
%Z=bitcast i8*%Y to i8**
store i8*%X,i8**%Z,align 8
%aa=getelementptr inbounds i8,i8*%T,i64 16
%ab=bitcast i8*%aa to i32*
store i32 3,i32*%ab,align 4
ret i8*%T
ac:
%ad=bitcast i8*%Q to i8**
%ae=load i8*,i8**%ad,align 8
store i8*%ae,i8**%d,align 8
%af=load i8*,i8**%g,align 8
%ag=bitcast i8*%af to i32*
%ah=load i32,i32*%ag,align 4
%ai=icmp eq i32%ah,0
br i1%ai,label%ao,label%aj
aj:
%ak=sext i32%x to i64
%al=getelementptr inbounds i8,i8*%ae,i64%ak
%am=bitcast i8*%al to i8**
%an=load i8*,i8**%am,align 8
br label%az
ao:
%ap=getelementptr inbounds i8,i8*%af,i64 4
%aq=bitcast i8*%ap to i32*
%ar=load i32,i32*%aq,align 4
%as=call i8*@sml_alloc(i32 inreg%ar)#0
%at=getelementptr inbounds i8,i8*%as,i64 -4
%au=bitcast i8*%at to i32*
store i32%ar,i32*%au,align 4
%av=load i8*,i8**%d,align 8
%aw=sext i32%x to i64
%ax=getelementptr inbounds i8,i8*%av,i64%aw
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%as,i8*%ax,i32%ar,i1 false)
%ay=load i8*,i8**%g,align 8
br label%az
az:
%aA=phi i64[%aw,%ao],[%ak,%aj]
%aB=phi i8*[%ay,%ao],[%af,%aj]
%aC=phi i8*[%av,%ao],[%ae,%aj]
%aD=phi i8*[%as,%ao],[%an,%aj]
store i8*%aD,i8**%f,align 8
store i8*null,i8**%d,align 8
%aE=sext i32%A to i64
%aF=getelementptr inbounds i8,i8*%aC,i64%aE
%aG=bitcast i8*%aF to i8**
%aH=load i8*,i8**%aG,align 8
%aI=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%aJ=call fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair10scanRepeatE_89(i8*inreg%aB,i8*inreg%aI,i8*inreg%aH)
%aK=bitcast i8*%aJ to i8**
%aL=load i8*,i8**%aK,align 8
store i8*%aL,i8**%d,align 8
%aM=getelementptr inbounds i8,i8*%aJ,i64 8
%aN=bitcast i8*%aM to i8**
%aO=load i8*,i8**%aN,align 8
store i8*%aO,i8**%e,align 8
%aP=load i8*,i8**%g,align 8
%aQ=getelementptr inbounds i8,i8*%aP,i64 4
%aR=bitcast i8*%aQ to i32*
%aS=load i32,i32*%aR,align 4
store i8*null,i8**%g,align 8
%aT=bitcast i8*%aP to i32*
%aU=load i32,i32*%aT,align 4
%aV=call i8*@sml_alloc(i32 inreg%K)#0
%aW=or i32%C,1342177280
%aX=getelementptr inbounds i8,i8*%aV,i64 -4
%aY=bitcast i8*%aX to i32*
store i32%aW,i32*%aY,align 4
store i8*%aV,i8**%g,align 8
call void@llvm.memset.p0i8.i32(i8*%aV,i8 0,i32%K,i1 false)
%aZ=icmp eq i32%aU,0
%a0=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%a1=getelementptr inbounds i8,i8*%aV,i64%aA
br i1%aZ,label%a4,label%a2
a2:
%a3=bitcast i8*%a1 to i8**
store i8*%a0,i8**%a3,align 8
br label%a5
a4:
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%a1,i8*%a0,i32%aS,i1 false)
br label%a5
a5:
%a6=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%a7=getelementptr inbounds i8,i8*%aV,i64%aE
%a8=bitcast i8*%a7 to i8**
store i8*%a6,i8**%a8,align 8
%a9=sext i32%C to i64
%ba=getelementptr inbounds i8,i8*%aV,i64%a9
%bb=bitcast i8*%ba to i32*
store i32%J,i32*%bb,align 4
%bc=call i8*@sml_alloc(i32 inreg 20)#0
%bd=getelementptr inbounds i8,i8*%bc,i64 -4
%be=bitcast i8*%bd to i32*
store i32 1342177296,i32*%be,align 4
%bf=load i8*,i8**%g,align 8
%bg=bitcast i8*%bc to i8**
store i8*%bf,i8**%bg,align 8
%bh=load i8*,i8**%e,align 8
%bi=getelementptr inbounds i8,i8*%bc,i64 8
%bj=bitcast i8*%bi to i8**
store i8*%bh,i8**%bj,align 8
%bk=getelementptr inbounds i8,i8*%bc,i64 16
%bl=bitcast i8*%bk to i32*
store i32 3,i32*%bl,align 4
ret i8*%bc
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair10scanRepeatE_90(i32 inreg%a,i32 inreg%b)unnamed_addr#4 gc"smlsharp"{
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
%d=call i8*@sml_alloc(i32 inreg 12)#0
%e=bitcast i8*%d to i32*
%f=getelementptr inbounds i8,i8*%d,i64 -4
%g=bitcast i8*%f to i32*
store i32 1342177288,i32*%g,align 4
store i8*%d,i8**%c,align 8
store i32%a,i32*%e,align 4
%h=getelementptr inbounds i8,i8*%d,i64 4
%i=bitcast i8*%h to i32*
store i32%b,i32*%i,align 4
%j=getelementptr inbounds i8,i8*%d,i64 8
%k=bitcast i8*%j to i32*
store i32 0,i32*%k,align 4
%l=call i8*@sml_alloc(i32 inreg 28)#0
%m=getelementptr inbounds i8,i8*%l,i64 -4
%n=bitcast i8*%m to i32*
store i32 1342177304,i32*%n,align 4
%o=load i8*,i8**%c,align 8
%p=bitcast i8*%l to i8**
store i8*%o,i8**%p,align 8
%q=getelementptr inbounds i8,i8*%l,i64 8
%r=bitcast i8*%q to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair10scanRepeatE_89 to void(...)*),void(...)**%r,align 8
%s=getelementptr inbounds i8,i8*%l,i64 16
%t=bitcast i8*%s to void(...)**
store void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair10scanRepeatE_89 to void(...)*),void(...)**%t,align 8
%u=getelementptr inbounds i8,i8*%l,i64 24
%v=bitcast i8*%u to i32*
store i32 -2147483647,i32*%v,align 4
ret i8*%l
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair10scanStringE_92(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%h,label%g
g:
call void@sml_check(i32 inreg%e)
br label%h
h:
%i=call fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair10scanRepeatE_90(i32 inreg 0,i32 inreg 1)
%j=getelementptr inbounds i8,i8*%i,i64 16
%k=bitcast i8*%j to i8*(i8*,i8*,i8*)**
%l=load i8*(i8*,i8*,i8*)*,i8*(i8*,i8*,i8*)**%k,align 8
%m=bitcast i8*%i to i8**
%n=load i8*,i8**%m,align 8
%o=bitcast i8**%d to i8***
%p=load i8**,i8***%o,align 8
store i8*null,i8**%d,align 8
%q=load i8*,i8**%p,align 8
%r=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%s=call fastcc i8*%l(i8*inreg%n,i8*inreg%q,i8*inreg%r)
%t=getelementptr inbounds i8,i8*%s,i64 8
%u=bitcast i8*%t to i8**
%v=load i8*,i8**%u,align 8
store i8*%v,i8**%c,align 8
%w=bitcast i8*%s to i8**
%x=load i8*,i8**%w,align 8
%y=call fastcc i8*@_SMLFN10CharVector8fromListE(i8*inreg%x)
store i8*%y,i8**%d,align 8
%z=call i8*@sml_alloc(i32 inreg 20)#0
%A=getelementptr inbounds i8,i8*%z,i64 -4
%B=bitcast i8*%A to i32*
store i32 1342177296,i32*%B,align 4
%C=load i8*,i8**%d,align 8
%D=bitcast i8*%z to i8**
store i8*%C,i8**%D,align 8
%E=load i8*,i8**%c,align 8
%F=getelementptr inbounds i8,i8*%z,i64 8
%G=bitcast i8*%F to i8**
store i8*%E,i8**%G,align 8
%H=getelementptr inbounds i8,i8*%z,i64 16
%I=bitcast i8*%H to i32*
store i32 3,i32*%I,align 4
ret i8*%z
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair10scanStringE_93(i8*inreg%a)unnamed_addr#4 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
%d=call i8*@sml_alloc(i32 inreg 12)#0
%e=getelementptr inbounds i8,i8*%d,i64 -4
%f=bitcast i8*%e to i32*
store i32 1342177288,i32*%f,align 4
store i8*%d,i8**%c,align 8
%g=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%h=bitcast i8*%d to i8**
store i8*%g,i8**%h,align 8
%i=getelementptr inbounds i8,i8*%d,i64 8
%j=bitcast i8*%i to i32*
store i32 1,i32*%j,align 4
%k=call i8*@sml_alloc(i32 inreg 28)#0
%l=getelementptr inbounds i8,i8*%k,i64 -4
%m=bitcast i8*%l to i32*
store i32 1342177304,i32*%m,align 4
%n=load i8*,i8**%c,align 8
%o=bitcast i8*%k to i8**
store i8*%n,i8**%o,align 8
%p=getelementptr inbounds i8,i8*%k,i64 8
%q=bitcast i8*%p to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair10scanStringE_92 to void(...)*),void(...)**%q,align 8
%r=getelementptr inbounds i8,i8*%k,i64 16
%s=bitcast i8*%r to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair10scanStringE_92 to void(...)*),void(...)**%s,align 8
%t=getelementptr inbounds i8,i8*%k,i64 24
%u=bitcast i8*%t to i32*
store i32 -2147483647,i32*%u,align 4
ret i8*%k
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair13scanValueCharE_95(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%c,align 8
store i8*%b,i8**%d,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%g,label%j
g:
%h=bitcast i8*%a to i8**
%i=bitcast i8**%c to i8***
br label%n
j:
call void@sml_check(i32 inreg%e)
%k=load i8*,i8**%d,align 8
%l=bitcast i8**%c to i8***
%m=load i8**,i8***%l,align 8
br label%n
n:
%o=phi i8***[%i,%g],[%l,%j]
%p=phi i8**[%h,%g],[%m,%j]
%q=phi i8*[%b,%g],[%k,%j]
store i8*null,i8**%d,align 8
%r=load i8*,i8**%p,align 8
%s=getelementptr inbounds i8,i8*%r,i64 16
%t=bitcast i8*%s to i8*(i8*,i8*)**
%u=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%t,align 8
%v=bitcast i8*%r to i8**
%w=load i8*,i8**%v,align 8
%x=call fastcc i8*%u(i8*inreg%w,i8*inreg%q)
%y=icmp eq i8*%x,null
br i1%y,label%z,label%A
z:
ret i8*null
A:
%B=bitcast i8*%x to i8**
%C=load i8*,i8**%B,align 8
%D=load i8,i8*%C,align 1
switch i8%D,label%E[
i8 39,label%z
i8 92,label%ab
]
E:
%F=getelementptr inbounds i8,i8*%C,i64 8
%G=bitcast i8*%F to i8**
%H=load i8*,i8**%G,align 8
store i8*%H,i8**%c,align 8
%I=call fastcc i32@_SMLFN4Char7isSpaceE(i8 inreg%D)
%J=icmp eq i32%I,0
br i1%J,label%K,label%z
K:
%L=call i8*@sml_alloc(i32 inreg 20)#0
%M=getelementptr inbounds i8,i8*%L,i64 -4
%N=bitcast i8*%M to i32*
store i32 1342177296,i32*%N,align 4
store i8*%L,i8**%d,align 8
%O=getelementptr inbounds i8,i8*%L,i64 1
call void@llvm.memset.p0i8.i32(i8*%O,i8 0,i32 7,i1 false)
store i8%D,i8*%L,align 1
%P=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%Q=getelementptr inbounds i8,i8*%L,i64 8
%R=bitcast i8*%Q to i8**
store i8*%P,i8**%R,align 8
%S=getelementptr inbounds i8,i8*%L,i64 16
%T=bitcast i8*%S to i32*
store i32 2,i32*%T,align 4
%U=call i8*@sml_alloc(i32 inreg 12)#0
%V=getelementptr inbounds i8,i8*%U,i64 -4
%W=bitcast i8*%V to i32*
store i32 1342177288,i32*%W,align 4
%X=load i8*,i8**%d,align 8
%Y=bitcast i8*%U to i8**
store i8*%X,i8**%Y,align 8
%Z=getelementptr inbounds i8,i8*%U,i64 8
%aa=bitcast i8*%Z to i32*
store i32 1,i32*%aa,align 4
ret i8*%U
ab:
%ac=load i8**,i8***%o,align 8
%ad=load i8*,i8**%ac,align 8
%ae=getelementptr inbounds i8,i8*%ad,i64 16
%af=bitcast i8*%ae to i8*(i8*,i8*)**
%ag=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%af,align 8
store i8*null,i8**%c,align 8
%ah=bitcast i8**%ac to i8***
%ai=load i8**,i8***%ah,align 8
%aj=load i8*,i8**%ai,align 8
%ak=getelementptr inbounds i8,i8*%C,i64 8
%al=bitcast i8*%ak to i8**
%am=load i8*,i8**%al,align 8
%an=call fastcc i8*%ag(i8*inreg%aj,i8*inreg%am)
%ao=icmp eq i8*%an,null
br i1%ao,label%z,label%ap
ap:
%aq=bitcast i8*%an to i8**
%ar=load i8*,i8**%aq,align 8
%as=load i8,i8*%ar,align 1
%at=getelementptr inbounds i8,i8*%ar,i64 8
%au=bitcast i8*%at to i8**
%av=load i8*,i8**%au,align 8
store i8*%av,i8**%c,align 8
%aw=call i8*@sml_alloc(i32 inreg 20)#0
%ax=getelementptr inbounds i8,i8*%aw,i64 -4
%ay=bitcast i8*%ax to i32*
store i32 1342177296,i32*%ay,align 4
store i8*%aw,i8**%d,align 8
%az=getelementptr inbounds i8,i8*%aw,i64 1
call void@llvm.memset.p0i8.i32(i8*%az,i8 0,i32 7,i1 false)
store i8%as,i8*%aw,align 1
%aA=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aB=getelementptr inbounds i8,i8*%aw,i64 8
%aC=bitcast i8*%aB to i8**
store i8*%aA,i8**%aC,align 8
%aD=getelementptr inbounds i8,i8*%aw,i64 16
%aE=bitcast i8*%aD to i32*
store i32 2,i32*%aE,align 4
%aF=call i8*@sml_alloc(i32 inreg 12)#0
%aG=getelementptr inbounds i8,i8*%aF,i64 -4
%aH=bitcast i8*%aG to i32*
store i32 1342177288,i32*%aH,align 4
%aI=load i8*,i8**%d,align 8
%aJ=bitcast i8*%aF to i8**
store i8*%aI,i8**%aJ,align 8
%aK=getelementptr inbounds i8,i8*%aF,i64 8
%aL=bitcast i8*%aK to i32*
store i32 1,i32*%aL,align 4
ret i8*%aF
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair13scanValueCharE_96(i8*inreg%a)unnamed_addr#4 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
%d=call i8*@sml_alloc(i32 inreg 12)#0
%e=getelementptr inbounds i8,i8*%d,i64 -4
%f=bitcast i8*%e to i32*
store i32 1342177288,i32*%f,align 4
store i8*%d,i8**%c,align 8
%g=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%h=bitcast i8*%d to i8**
store i8*%g,i8**%h,align 8
%i=getelementptr inbounds i8,i8*%d,i64 8
%j=bitcast i8*%i to i32*
store i32 1,i32*%j,align 4
%k=call i8*@sml_alloc(i32 inreg 28)#0
%l=getelementptr inbounds i8,i8*%k,i64 -4
%m=bitcast i8*%l to i32*
store i32 1342177304,i32*%m,align 4
%n=load i8*,i8**%c,align 8
%o=bitcast i8*%k to i8**
store i8*%n,i8**%o,align 8
%p=getelementptr inbounds i8,i8*%k,i64 8
%q=bitcast i8*%p to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair13scanValueCharE_95 to void(...)*),void(...)**%q,align 8
%r=getelementptr inbounds i8,i8*%k,i64 16
%s=bitcast i8*%r to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair13scanValueCharE_95 to void(...)*),void(...)**%s,align 8
%t=getelementptr inbounds i8,i8*%k,i64 24
%u=bitcast i8*%t to i32*
store i32 -2147483647,i32*%u,align 4
ret i8*%k
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair19scanValueCharQuotedE_98(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%g,label%j
g:
%h=bitcast i8*%a to i8**
%i=bitcast i8**%d to i8***
br label%m
j:
call void@sml_check(i32 inreg%e)
%k=bitcast i8**%d to i8***
%l=load i8**,i8***%k,align 8
br label%m
m:
%n=phi i8***[%i,%g],[%k,%j]
%o=phi i8**[%h,%g],[%l,%j]
%p=load i8*,i8**%o,align 8
%q=call fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair13scanValueCharE_96(i8*inreg%p)
%r=getelementptr inbounds i8,i8*%q,i64 16
%s=bitcast i8*%r to i8*(i8*,i8*)**
%t=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%s,align 8
%u=bitcast i8*%q to i8**
%v=load i8*,i8**%u,align 8
%w=load i8*,i8**%c,align 8
%x=call fastcc i8*%t(i8*inreg%v,i8*inreg%w)
%y=icmp eq i8*%x,null
br i1%y,label%z,label%am
z:
%A=load i8**,i8***%n,align 8
%B=load i8*,i8**%A,align 8
%C=getelementptr inbounds i8,i8*%B,i64 16
%D=bitcast i8*%C to i8*(i8*,i8*)**
%E=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%D,align 8
store i8*null,i8**%d,align 8
%F=bitcast i8**%A to i8***
%G=load i8**,i8***%F,align 8
%H=load i8*,i8**%G,align 8
%I=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%J=call fastcc i8*%E(i8*inreg%H,i8*inreg%I)
%K=icmp eq i8*%J,null
br i1%K,label%L,label%M
L:
ret i8*null
M:
%N=bitcast i8*%J to i8**
%O=load i8*,i8**%N,align 8
%P=load i8,i8*%O,align 1
%Q=getelementptr inbounds i8,i8*%O,i64 8
%R=bitcast i8*%Q to i8**
%S=load i8*,i8**%R,align 8
store i8*%S,i8**%c,align 8
%T=call fastcc i32@_SMLFN4Char7isSpaceE(i8 inreg%P)
%U=icmp eq i32%T,0
br i1%U,label%L,label%V
V:
%W=call i8*@sml_alloc(i32 inreg 20)#0
%X=getelementptr inbounds i8,i8*%W,i64 -4
%Y=bitcast i8*%X to i32*
store i32 1342177296,i32*%Y,align 4
store i8*%W,i8**%d,align 8
%Z=getelementptr inbounds i8,i8*%W,i64 1
call void@llvm.memset.p0i8.i32(i8*%Z,i8 0,i32 7,i1 false)
store i8%P,i8*%W,align 1
%aa=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ab=getelementptr inbounds i8,i8*%W,i64 8
%ac=bitcast i8*%ab to i8**
store i8*%aa,i8**%ac,align 8
%ad=getelementptr inbounds i8,i8*%W,i64 16
%ae=bitcast i8*%ad to i32*
store i32 2,i32*%ae,align 4
%af=call i8*@sml_alloc(i32 inreg 12)#0
%ag=getelementptr inbounds i8,i8*%af,i64 -4
%ah=bitcast i8*%ag to i32*
store i32 1342177288,i32*%ah,align 4
%ai=load i8*,i8**%d,align 8
%aj=bitcast i8*%af to i8**
store i8*%ai,i8**%aj,align 8
%ak=getelementptr inbounds i8,i8*%af,i64 8
%al=bitcast i8*%ak to i32*
store i32 1,i32*%al,align 4
ret i8*%af
am:
store i8*null,i8**%d,align 8
%an=bitcast i8*%x to i8**
%ao=load i8*,i8**%an,align 8
%ap=load i8,i8*%ao,align 1
%aq=getelementptr inbounds i8,i8*%ao,i64 8
%ar=bitcast i8*%aq to i8**
%as=load i8*,i8**%ar,align 8
store i8*%as,i8**%c,align 8
%at=call i8*@sml_alloc(i32 inreg 20)#0
%au=getelementptr inbounds i8,i8*%at,i64 -4
%av=bitcast i8*%au to i32*
store i32 1342177296,i32*%av,align 4
store i8*%at,i8**%d,align 8
%aw=getelementptr inbounds i8,i8*%at,i64 1
call void@llvm.memset.p0i8.i32(i8*%aw,i8 0,i32 7,i1 false)
store i8%ap,i8*%at,align 1
%ax=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ay=getelementptr inbounds i8,i8*%at,i64 8
%az=bitcast i8*%ay to i8**
store i8*%ax,i8**%az,align 8
%aA=getelementptr inbounds i8,i8*%at,i64 16
%aB=bitcast i8*%aA to i32*
store i32 2,i32*%aB,align 4
%aC=call i8*@sml_alloc(i32 inreg 12)#0
%aD=getelementptr inbounds i8,i8*%aC,i64 -4
%aE=bitcast i8*%aD to i32*
store i32 1342177288,i32*%aE,align 4
%aF=load i8*,i8**%d,align 8
%aG=bitcast i8*%aC to i8**
store i8*%aF,i8**%aG,align 8
%aH=getelementptr inbounds i8,i8*%aC,i64 8
%aI=bitcast i8*%aH to i32*
store i32 1,i32*%aI,align 4
ret i8*%aC
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair9scanValueE_101(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
store i8*%a,i8**%g,align 8
store i8*%b,i8**%e,align 8
%h=load atomic i32,i32*@sml_check_flag unordered,align 4
%i=icmp eq i32%h,0
br i1%i,label%j,label%m
j:
%k=bitcast i8*%a to i8**
%l=bitcast i8**%g to i8***
br label%q
m:
call void@sml_check(i32 inreg%h)
%n=load i8*,i8**%e,align 8
%o=bitcast i8**%g to i8***
%p=load i8**,i8***%o,align 8
br label%q
q:
%r=phi i8***[%l,%j],[%o,%m]
%s=phi i8**[%k,%j],[%p,%m]
%t=phi i8*[%b,%j],[%n,%m]
%u=load i8*,i8**%s,align 8
%v=getelementptr inbounds i8,i8*%u,i64 16
%w=bitcast i8*%v to i8*(i8*,i8*)**
%x=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%w,align 8
%y=bitcast i8*%u to i8**
%z=load i8*,i8**%y,align 8
%A=call fastcc i8*%x(i8*inreg%z,i8*inreg%t)
%B=icmp eq i8*%A,null
br i1%B,label%C,label%D
C:
ret i8*null
D:
%E=bitcast i8*%A to i8**
%F=load i8*,i8**%E,align 8
store i8*%F,i8**%f,align 8
%G=load i8,i8*%F,align 1
%H=icmp eq i8%G,39
br i1%H,label%ab,label%I
I:
store i8*null,i8**%f,align 8
%J=load i8**,i8***%r,align 8
store i8*null,i8**%g,align 8
%K=load i8*,i8**%J,align 8
%L=call fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair13scanValueCharE_96(i8*inreg%K)
%M=call fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair10scanStringE_93(i8*inreg%L)
%N=getelementptr inbounds i8,i8*%M,i64 16
%O=bitcast i8*%N to i8*(i8*,i8*)**
%P=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%O,align 8
%Q=bitcast i8*%M to i8**
%R=load i8*,i8**%Q,align 8
%S=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%T=call fastcc i8*%P(i8*inreg%R,i8*inreg%S)
store i8*%T,i8**%e,align 8
%U=call i8*@sml_alloc(i32 inreg 12)#0
%V=getelementptr inbounds i8,i8*%U,i64 -4
%W=bitcast i8*%V to i32*
store i32 1342177288,i32*%W,align 4
%X=load i8*,i8**%e,align 8
%Y=bitcast i8*%U to i8**
store i8*%X,i8**%Y,align 8
%Z=getelementptr inbounds i8,i8*%U,i64 8
%aa=bitcast i8*%Z to i32*
store i32 1,i32*%aa,align 4
ret i8*%U
ab:
store i8*null,i8**%e,align 8
%ac=load i8**,i8***%r,align 8
%ad=load i8*,i8**%ac,align 8
%ae=bitcast i8**%c to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%ae)
%af=bitcast i8**%d to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%af)
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%ad,i8**%c,align 8
%ag=call i8*@sml_alloc(i32 inreg 12)#0
%ah=getelementptr inbounds i8,i8*%ag,i64 -4
%ai=bitcast i8*%ah to i32*
store i32 1342177288,i32*%ai,align 4
store i8*%ag,i8**%d,align 8
%aj=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ak=bitcast i8*%ag to i8**
store i8*%aj,i8**%ak,align 8
%al=getelementptr inbounds i8,i8*%ag,i64 8
%am=bitcast i8*%al to i32*
store i32 1,i32*%am,align 4
%an=call i8*@sml_alloc(i32 inreg 28)#0
%ao=getelementptr inbounds i8,i8*%an,i64 -4
%ap=bitcast i8*%ao to i32*
store i32 1342177304,i32*%ap,align 4
%aq=load i8*,i8**%d,align 8
%ar=bitcast i8*%an to i8**
store i8*%aq,i8**%ar,align 8
%as=getelementptr inbounds i8,i8*%an,i64 8
%at=bitcast i8*%as to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair19scanValueCharQuotedE_98 to void(...)*),void(...)**%at,align 8
%au=getelementptr inbounds i8,i8*%an,i64 16
%av=bitcast i8*%au to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair19scanValueCharQuotedE_98 to void(...)*),void(...)**%av,align 8
%aw=getelementptr inbounds i8,i8*%an,i64 24
%ax=bitcast i8*%aw to i32*
store i32 -2147483647,i32*%ax,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%ae)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%af)
%ay=call fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair10scanStringE_93(i8*inreg%an)
%az=getelementptr inbounds i8,i8*%ay,i64 16
%aA=bitcast i8*%az to i8*(i8*,i8*)**
%aB=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aA,align 8
%aC=bitcast i8*%ay to i8**
%aD=load i8*,i8**%aC,align 8
%aE=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%aF=getelementptr inbounds i8,i8*%aE,i64 8
%aG=bitcast i8*%aF to i8**
%aH=load i8*,i8**%aG,align 8
%aI=call fastcc i8*%aB(i8*inreg%aD,i8*inreg%aH)
%aJ=bitcast i8*%aI to i8**
%aK=load i8*,i8**%aJ,align 8
store i8*%aK,i8**%e,align 8
%aL=load i8**,i8***%r,align 8
%aM=load i8*,i8**%aL,align 8
%aN=getelementptr inbounds i8,i8*%aM,i64 16
%aO=bitcast i8*%aN to i8*(i8*,i8*)**
%aP=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%aO,align 8
store i8*null,i8**%g,align 8
%aQ=bitcast i8**%aL to i8***
%aR=load i8**,i8***%aQ,align 8
%aS=load i8*,i8**%aR,align 8
%aT=getelementptr inbounds i8,i8*%aI,i64 8
%aU=bitcast i8*%aT to i8**
%aV=load i8*,i8**%aU,align 8
%aW=call fastcc i8*%aP(i8*inreg%aS,i8*inreg%aV)
%aX=icmp eq i8*%aW,null
br i1%aX,label%C,label%aY
aY:
%aZ=bitcast i8*%aW to i8**
%a0=load i8*,i8**%aZ,align 8
%a1=load i8,i8*%a0,align 1
%a2=icmp eq i8%a1,39
br i1%a2,label%a3,label%C
a3:
%a4=getelementptr inbounds i8,i8*%a0,i64 8
%a5=bitcast i8*%a4 to i8**
%a6=load i8*,i8**%a5,align 8
store i8*%a6,i8**%f,align 8
%a7=call i8*@sml_alloc(i32 inreg 20)#0
%a8=getelementptr inbounds i8,i8*%a7,i64 -4
%a9=bitcast i8*%a8 to i32*
store i32 1342177296,i32*%a9,align 4
store i8*%a7,i8**%g,align 8
%ba=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%bb=bitcast i8*%a7 to i8**
store i8*%ba,i8**%bb,align 8
%bc=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%bd=getelementptr inbounds i8,i8*%a7,i64 8
%be=bitcast i8*%bd to i8**
store i8*%bc,i8**%be,align 8
%bf=getelementptr inbounds i8,i8*%a7,i64 16
%bg=bitcast i8*%bf to i32*
store i32 3,i32*%bg,align 4
%bh=call i8*@sml_alloc(i32 inreg 12)#0
%bi=getelementptr inbounds i8,i8*%bh,i64 -4
%bj=bitcast i8*%bi to i32*
store i32 1342177288,i32*%bj,align 4
%bk=load i8*,i8**%g,align 8
%bl=bitcast i8*%bh to i8**
store i8*%bk,i8**%bl,align 8
%bm=getelementptr inbounds i8,i8*%bh,i64 8
%bn=bitcast i8*%bm to i32*
store i32 1,i32*%bn,align 4
ret i8*%bh
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair11scanKeyCharE_104(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%c,align 8
store i8*%b,i8**%d,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%g,label%i
g:
%h=bitcast i8*%a to i8**
br label%m
i:
call void@sml_check(i32 inreg%e)
%j=load i8*,i8**%d,align 8
%k=bitcast i8**%c to i8***
%l=load i8**,i8***%k,align 8
br label%m
m:
%n=phi i8**[%l,%i],[%h,%g]
%o=phi i8*[%j,%i],[%b,%g]
store i8*null,i8**%d,align 8
%p=load i8*,i8**%n,align 8
%q=getelementptr inbounds i8,i8*%p,i64 16
%r=bitcast i8*%q to i8*(i8*,i8*)**
%s=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%r,align 8
store i8*null,i8**%c,align 8
%t=bitcast i8**%n to i8***
%u=load i8**,i8***%t,align 8
%v=load i8*,i8**%u,align 8
%w=call fastcc i8*%s(i8*inreg%v,i8*inreg%o)
%x=icmp eq i8*%w,null
br i1%x,label%y,label%z
y:
ret i8*null
z:
%A=bitcast i8*%w to i8**
%B=load i8*,i8**%A,align 8
%C=load i8,i8*%B,align 1
%D=icmp eq i8%C,95
%E=getelementptr inbounds i8,i8*%B,i64 8
%F=bitcast i8*%E to i8**
%G=load i8*,i8**%F,align 8
store i8*%G,i8**%c,align 8
br i1%D,label%ab,label%H
H:
%I=call fastcc i32@_SMLFN4Char10isAlphaNumE(i8 inreg%C)
%J=icmp eq i32%I,0
br i1%J,label%y,label%K
K:
%L=call i8*@sml_alloc(i32 inreg 20)#0
%M=getelementptr inbounds i8,i8*%L,i64 -4
%N=bitcast i8*%M to i32*
store i32 1342177296,i32*%N,align 4
store i8*%L,i8**%d,align 8
%O=getelementptr inbounds i8,i8*%L,i64 1
call void@llvm.memset.p0i8.i32(i8*%O,i8 0,i32 7,i1 false)
store i8%C,i8*%L,align 1
%P=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%Q=getelementptr inbounds i8,i8*%L,i64 8
%R=bitcast i8*%Q to i8**
store i8*%P,i8**%R,align 8
%S=getelementptr inbounds i8,i8*%L,i64 16
%T=bitcast i8*%S to i32*
store i32 2,i32*%T,align 4
%U=call i8*@sml_alloc(i32 inreg 12)#0
%V=getelementptr inbounds i8,i8*%U,i64 -4
%W=bitcast i8*%V to i32*
store i32 1342177288,i32*%W,align 4
%X=load i8*,i8**%d,align 8
%Y=bitcast i8*%U to i8**
store i8*%X,i8**%Y,align 8
%Z=getelementptr inbounds i8,i8*%U,i64 8
%aa=bitcast i8*%Z to i32*
store i32 1,i32*%aa,align 4
ret i8*%U
ab:
%ac=call i8*@sml_alloc(i32 inreg 20)#0
%ad=getelementptr inbounds i8,i8*%ac,i64 -4
%ae=bitcast i8*%ad to i32*
store i32 1342177296,i32*%ae,align 4
store i8*%ac,i8**%d,align 8
%af=getelementptr inbounds i8,i8*%ac,i64 1
call void@llvm.memset.p0i8.i32(i8*%af,i8 0,i32 7,i1 false)
store i8 95,i8*%ac,align 1
%ag=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%ah=getelementptr inbounds i8,i8*%ac,i64 8
%ai=bitcast i8*%ah to i8**
store i8*%ag,i8**%ai,align 8
%aj=getelementptr inbounds i8,i8*%ac,i64 16
%ak=bitcast i8*%aj to i32*
store i32 2,i32*%ak,align 4
%al=call i8*@sml_alloc(i32 inreg 12)#0
%am=getelementptr inbounds i8,i8*%al,i64 -4
%an=bitcast i8*%am to i32*
store i32 1342177288,i32*%an,align 4
%ao=load i8*,i8**%d,align 8
%ap=bitcast i8*%al to i8**
store i8*%ao,i8**%ap,align 8
%aq=getelementptr inbounds i8,i8*%al,i64 8
%ar=bitcast i8*%aq to i32*
store i32 1,i32*%ar,align 4
ret i8*%al
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair7scanKeyE_107(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
store i8*%a,i8**%f,align 8
store i8*%b,i8**%e,align 8
%h=load atomic i32,i32*@sml_check_flag unordered,align 4
%i=icmp eq i32%h,0
br i1%i,label%j,label%l
j:
%k=bitcast i8*%a to i8**
br label%o
l:
call void@sml_check(i32 inreg%h)
%m=bitcast i8**%f to i8***
%n=load i8**,i8***%m,align 8
br label%o
o:
%p=phi i8**[%n,%l],[%k,%j]
store i8*null,i8**%f,align 8
%q=load i8*,i8**%p,align 8
%r=bitcast i8**%c to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%r)
%s=bitcast i8**%d to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%s)
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%q,i8**%c,align 8
%t=call i8*@sml_alloc(i32 inreg 12)#0
%u=getelementptr inbounds i8,i8*%t,i64 -4
%v=bitcast i8*%u to i32*
store i32 1342177288,i32*%v,align 4
store i8*%t,i8**%d,align 8
%w=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%x=bitcast i8*%t to i8**
store i8*%w,i8**%x,align 8
%y=getelementptr inbounds i8,i8*%t,i64 8
%z=bitcast i8*%y to i32*
store i32 1,i32*%z,align 4
%A=call i8*@sml_alloc(i32 inreg 28)#0
%B=getelementptr inbounds i8,i8*%A,i64 -4
%C=bitcast i8*%B to i32*
store i32 1342177304,i32*%C,align 4
%D=load i8*,i8**%d,align 8
%E=bitcast i8*%A to i8**
store i8*%D,i8**%E,align 8
%F=getelementptr inbounds i8,i8*%A,i64 8
%G=bitcast i8*%F to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair11scanKeyCharE_104 to void(...)*),void(...)**%G,align 8
%H=getelementptr inbounds i8,i8*%A,i64 16
%I=bitcast i8*%H to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair11scanKeyCharE_104 to void(...)*),void(...)**%I,align 8
%J=getelementptr inbounds i8,i8*%A,i64 24
%K=bitcast i8*%J to i32*
store i32 -2147483647,i32*%K,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%r)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%s)
%L=call fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair10scanStringE_93(i8*inreg%A)
%M=getelementptr inbounds i8,i8*%L,i64 16
%N=bitcast i8*%M to i8*(i8*,i8*)**
%O=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%N,align 8
%P=bitcast i8*%L to i8**
%Q=load i8*,i8**%P,align 8
%R=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%S=call fastcc i8*%O(i8*inreg%Q,i8*inreg%R)
%T=bitcast i8*%S to i8**
%U=load i8*,i8**%T,align 8
store i8*%U,i8**%e,align 8
%V=getelementptr inbounds i8,i8*%S,i64 8
%W=bitcast i8*%V to i8**
%X=load i8*,i8**%W,align 8
store i8*%X,i8**%f,align 8
%Y=getelementptr inbounds i8,i8*%U,i64 -4
%Z=bitcast i8*%Y to i32*
%aa=load i32,i32*%Z,align 4
%ab=and i32%aa,268435454
%ac=icmp eq i32%ab,0
br i1%ac,label%av,label%ad
ad:
%ae=call i8*@sml_alloc(i32 inreg 20)#0
%af=getelementptr inbounds i8,i8*%ae,i64 -4
%ag=bitcast i8*%af to i32*
store i32 1342177296,i32*%ag,align 4
store i8*%ae,i8**%g,align 8
%ah=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%ai=bitcast i8*%ae to i8**
store i8*%ah,i8**%ai,align 8
%aj=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ak=getelementptr inbounds i8,i8*%ae,i64 8
%al=bitcast i8*%ak to i8**
store i8*%aj,i8**%al,align 8
%am=getelementptr inbounds i8,i8*%ae,i64 16
%an=bitcast i8*%am to i32*
store i32 3,i32*%an,align 4
%ao=call i8*@sml_alloc(i32 inreg 12)#0
%ap=getelementptr inbounds i8,i8*%ao,i64 -4
%aq=bitcast i8*%ap to i32*
store i32 1342177288,i32*%aq,align 4
%ar=load i8*,i8**%g,align 8
%as=bitcast i8*%ao to i8**
store i8*%ar,i8**%as,align 8
%at=getelementptr inbounds i8,i8*%ao,i64 8
%au=bitcast i8*%at to i32*
store i32 1,i32*%au,align 4
ret i8*%ao
av:
ret i8*null
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair9skipSpaceE_110(i8*inreg%a,i8*inreg%b)unnamed_addr#2 gc"smlsharp"{
h:
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%a,i8**%d,align 8
br label%f
f:
%g=phi i8*[%I,%E],[%b,%h]
store i8*%g,i8**%c,align 8
%i=load atomic i32,i32*@sml_check_flag unordered,align 4
%j=icmp eq i32%i,0
br i1%j,label%m,label%k
k:
call void@sml_check(i32 inreg%i)
%l=load i8*,i8**%c,align 8
br label%m
m:
%n=phi i8*[%l,%k],[%g,%f]
%o=load i8*,i8**%d,align 8
%p=getelementptr inbounds i8,i8*%o,i64 16
%q=bitcast i8*%p to i8*(i8*,i8*)**
%r=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%q,align 8
%s=bitcast i8*%o to i8**
%t=load i8*,i8**%s,align 8
%u=call fastcc i8*%r(i8*inreg%t,i8*inreg%n)
%v=icmp eq i8*%u,null
br i1%v,label%w,label%y
w:
%x=load i8*,i8**%c,align 8
ret i8*%x
y:
%z=bitcast i8*%u to i8**
%A=load i8*,i8**%z,align 8
store i8*%A,i8**%e,align 8
%B=load i8,i8*%A,align 1
%C=call fastcc i32@_SMLFN4Char7isSpaceE(i8 inreg%B)
%D=icmp eq i32%C,0
br i1%D,label%J,label%E
E:
store i8*null,i8**%c,align 8
%F=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%G=getelementptr inbounds i8,i8*%F,i64 8
%H=bitcast i8*%G to i8**
%I=load i8*,i8**%H,align 8
br label%f
J:
%K=load i8*,i8**%c,align 8
ret i8*%K
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair8scanPairE_112(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
%h=alloca i8*,align 8
%i=alloca i8*,align 8
%j=alloca i8*,align 8
call void@llvm.gcroot(i8**%g,i8*null)#0
call void@llvm.gcroot(i8**%h,i8*null)#0
call void@llvm.gcroot(i8**%i,i8*null)#0
call void@llvm.gcroot(i8**%j,i8*null)#0
store i8*%a,i8**%i,align 8
store i8*%b,i8**%g,align 8
%k=load atomic i32,i32*@sml_check_flag unordered,align 4
%l=icmp eq i32%k,0
br i1%l,label%m,label%p
m:
%n=bitcast i8*%a to i8**
%o=bitcast i8**%i to i8***
br label%s
p:
call void@sml_check(i32 inreg%k)
%q=bitcast i8**%i to i8***
%r=load i8**,i8***%q,align 8
br label%s
s:
%t=phi i8***[%o,%m],[%q,%p]
%u=phi i8**[%n,%m],[%r,%p]
%v=load i8*,i8**%u,align 8
%w=bitcast i8**%e to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%w)
%x=bitcast i8**%f to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%x)
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%v,i8**%e,align 8
%y=call i8*@sml_alloc(i32 inreg 12)#0
%z=getelementptr inbounds i8,i8*%y,i64 -4
%A=bitcast i8*%z to i32*
store i32 1342177288,i32*%A,align 4
store i8*%y,i8**%f,align 8
%B=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%C=bitcast i8*%y to i8**
store i8*%B,i8**%C,align 8
%D=getelementptr inbounds i8,i8*%y,i64 8
%E=bitcast i8*%D to i32*
store i32 1,i32*%E,align 4
%F=call i8*@sml_alloc(i32 inreg 28)#0
%G=getelementptr inbounds i8,i8*%F,i64 -4
%H=bitcast i8*%G to i32*
store i32 1342177304,i32*%H,align 4
%I=load i8*,i8**%f,align 8
%J=bitcast i8*%F to i8**
store i8*%I,i8**%J,align 8
%K=getelementptr inbounds i8,i8*%F,i64 8
%L=bitcast i8*%K to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair7scanKeyE_107 to void(...)*),void(...)**%L,align 8
%M=getelementptr inbounds i8,i8*%F,i64 16
%N=bitcast i8*%M to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair7scanKeyE_107 to void(...)*),void(...)**%N,align 8
%O=getelementptr inbounds i8,i8*%F,i64 24
%P=bitcast i8*%O to i32*
store i32 -2147483647,i32*%P,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%w)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%x)
store i8*%I,i8**%h,align 8
%Q=load i8**,i8***%t,align 8
%R=load i8*,i8**%Q,align 8
%S=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%T=call fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair9skipSpaceE_110(i8*inreg%R,i8*inreg%S)
%U=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%V=call fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair7scanKeyE_107(i8*inreg%U,i8*inreg%T)
%W=icmp eq i8*%V,null
br i1%W,label%X,label%Y
X:
ret i8*null
Y:
%Z=bitcast i8*%V to i8**
%aa=load i8*,i8**%Z,align 8
%ab=bitcast i8*%aa to i8**
%ac=load i8*,i8**%ab,align 8
store i8*%ac,i8**%g,align 8
%ad=load i8**,i8***%t,align 8
%ae=load i8*,i8**%ad,align 8
%af=getelementptr inbounds i8,i8*%ae,i64 16
%ag=bitcast i8*%af to i8*(i8*,i8*)**
%ah=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%ag,align 8
%ai=bitcast i8*%ae to i8**
%aj=load i8*,i8**%ai,align 8
store i8*%aj,i8**%h,align 8
%ak=load i8*,i8**%ad,align 8
%al=getelementptr inbounds i8,i8*%aa,i64 8
%am=bitcast i8*%al to i8**
%an=load i8*,i8**%am,align 8
%ao=call fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair9skipSpaceE_110(i8*inreg%ak,i8*inreg%an)
%ap=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%aq=call fastcc i8*%ah(i8*inreg%ap,i8*inreg%ao)
%ar=icmp eq i8*%aq,null
br i1%ar,label%X,label%as
as:
%at=bitcast i8*%aq to i8**
%au=load i8*,i8**%at,align 8
store i8*%au,i8**%h,align 8
%av=load i8,i8*%au,align 1
%aw=icmp eq i8%av,61
br i1%aw,label%ax,label%X
ax:
%ay=load i8**,i8***%t,align 8
%az=load i8*,i8**%ay,align 8
%aA=bitcast i8**%c to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%aA)
%aB=bitcast i8**%d to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%aB)
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%az,i8**%c,align 8
%aC=call i8*@sml_alloc(i32 inreg 12)#0
%aD=getelementptr inbounds i8,i8*%aC,i64 -4
%aE=bitcast i8*%aD to i32*
store i32 1342177288,i32*%aE,align 4
store i8*%aC,i8**%d,align 8
%aF=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aG=bitcast i8*%aC to i8**
store i8*%aF,i8**%aG,align 8
%aH=getelementptr inbounds i8,i8*%aC,i64 8
%aI=bitcast i8*%aH to i32*
store i32 1,i32*%aI,align 4
%aJ=call i8*@sml_alloc(i32 inreg 28)#0
%aK=getelementptr inbounds i8,i8*%aJ,i64 -4
%aL=bitcast i8*%aK to i32*
store i32 1342177304,i32*%aL,align 4
%aM=load i8*,i8**%d,align 8
%aN=bitcast i8*%aJ to i8**
store i8*%aM,i8**%aN,align 8
%aO=getelementptr inbounds i8,i8*%aJ,i64 8
%aP=bitcast i8*%aO to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair9scanValueE_101 to void(...)*),void(...)**%aP,align 8
%aQ=getelementptr inbounds i8,i8*%aJ,i64 16
%aR=bitcast i8*%aQ to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair9scanValueE_101 to void(...)*),void(...)**%aR,align 8
%aS=getelementptr inbounds i8,i8*%aJ,i64 24
%aT=bitcast i8*%aS to i32*
store i32 -2147483647,i32*%aT,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%aA)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%aB)
store i8*%aM,i8**%j,align 8
%aU=load i8**,i8***%t,align 8
store i8*null,i8**%i,align 8
%aV=load i8*,i8**%aU,align 8
%aW=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%aX=getelementptr inbounds i8,i8*%aW,i64 8
%aY=bitcast i8*%aX to i8**
%aZ=load i8*,i8**%aY,align 8
%a0=call fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair9skipSpaceE_110(i8*inreg%aV,i8*inreg%aZ)
%a1=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%a2=call fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair9scanValueE_101(i8*inreg%a1,i8*inreg%a0)
%a3=icmp eq i8*%a2,null
br i1%a3,label%X,label%a4
a4:
%a5=bitcast i8*%a2 to i8**
%a6=load i8*,i8**%a5,align 8
%a7=bitcast i8*%a6 to i8**
%a8=load i8*,i8**%a7,align 8
store i8*%a8,i8**%h,align 8
%a9=getelementptr inbounds i8,i8*%a6,i64 8
%ba=bitcast i8*%a9 to i8**
%bb=load i8*,i8**%ba,align 8
store i8*%bb,i8**%i,align 8
%bc=call i8*@sml_alloc(i32 inreg 20)#0
%bd=getelementptr inbounds i8,i8*%bc,i64 -4
%be=bitcast i8*%bd to i32*
store i32 1342177296,i32*%be,align 4
store i8*%bc,i8**%j,align 8
%bf=load i8*,i8**%g,align 8
store i8*null,i8**%g,align 8
%bg=bitcast i8*%bc to i8**
store i8*%bf,i8**%bg,align 8
%bh=load i8*,i8**%h,align 8
store i8*null,i8**%h,align 8
%bi=getelementptr inbounds i8,i8*%bc,i64 8
%bj=bitcast i8*%bi to i8**
store i8*%bh,i8**%bj,align 8
%bk=getelementptr inbounds i8,i8*%bc,i64 16
%bl=bitcast i8*%bk to i32*
store i32 3,i32*%bl,align 4
%bm=call i8*@sml_alloc(i32 inreg 20)#0
%bn=getelementptr inbounds i8,i8*%bm,i64 -4
%bo=bitcast i8*%bn to i32*
store i32 1342177296,i32*%bo,align 4
store i8*%bm,i8**%g,align 8
%bp=load i8*,i8**%j,align 8
store i8*null,i8**%j,align 8
%bq=bitcast i8*%bm to i8**
store i8*%bp,i8**%bq,align 8
%br=load i8*,i8**%i,align 8
store i8*null,i8**%i,align 8
%bs=getelementptr inbounds i8,i8*%bm,i64 8
%bt=bitcast i8*%bs to i8**
store i8*%br,i8**%bt,align 8
%bu=getelementptr inbounds i8,i8*%bm,i64 16
%bv=bitcast i8*%bu to i32*
store i32 3,i32*%bv,align 4
%bw=call i8*@sml_alloc(i32 inreg 12)#0
%bx=getelementptr inbounds i8,i8*%bw,i64 -4
%by=bitcast i8*%bx to i32*
store i32 1342177288,i32*%by,align 4
%bz=load i8*,i8**%g,align 8
%bA=bitcast i8*%bw to i8**
store i8*%bz,i8**%bA,align 8
%bB=getelementptr inbounds i8,i8*%bw,i64 8
%bC=bitcast i8*%bB to i32*
store i32 1,i32*%bC,align 4
ret i8*%bw
}
define internal fastcc i32@_SMLLN25SMLSharp__SQL__KeyValuePair11endOfSourceE_115(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
store i8*%a,i8**%c,align 8
store i8*%b,i8**%d,align 8
%e=load atomic i32,i32*@sml_check_flag unordered,align 4
%f=icmp eq i32%e,0
br i1%f,label%g,label%i
g:
%h=bitcast i8*%a to i8**
br label%m
i:
call void@sml_check(i32 inreg%e)
%j=load i8*,i8**%d,align 8
%k=bitcast i8**%c to i8***
%l=load i8**,i8***%k,align 8
br label%m
m:
%n=phi i8**[%l,%i],[%h,%g]
%o=phi i8*[%j,%i],[%b,%g]
%p=load i8*,i8**%n,align 8
%q=getelementptr inbounds i8,i8*%p,i64 16
%r=bitcast i8*%q to i8*(i8*,i8*)**
%s=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%r,align 8
%t=bitcast i8*%p to i8**
%u=load i8*,i8**%t,align 8
store i8*%u,i8**%d,align 8
store i8*null,i8**%c,align 8
%v=load i8*,i8**%n,align 8
%w=call fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair9skipSpaceE_110(i8*inreg%v,i8*inreg%o)
%x=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%y=call fastcc i8*%s(i8*inreg%x,i8*inreg%w)
%z=icmp eq i8*%y,null
%A=zext i1%z to i32
ret i32%A
}
define fastcc i8*@_SMLFN25SMLSharp__SQL__KeyValuePair5parseE(i8*inreg%a)#2 gc"smlsharp"{
n:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
%g=alloca i8*,align 8
call void@llvm.gcroot(i8**%f,i8*null)#0
call void@llvm.gcroot(i8**%g,i8*null)#0
store i8*%a,i8**%f,align 8
%h=load atomic i32,i32*@sml_check_flag unordered,align 4
%i=icmp eq i32%h,0
br i1%i,label%l,label%j
j:
call void@sml_check(i32 inreg%h)
%k=load i8*,i8**%f,align 8
br label%l
l:
%m=phi i8*[%k,%j],[%a,%n]
store i8*null,i8**%f,align 8
%o=call fastcc i8*@_SMLFN9Substring4fullE(i8*inreg%m)
store i8*%o,i8**%f,align 8
%p=call fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair10scanRepeatE_90(i32 inreg 1,i32 inreg 8)
%q=getelementptr inbounds i8,i8*%p,i64 16
%r=bitcast i8*%q to i8*(i8*,i8*,i8*)**
%s=load i8*(i8*,i8*,i8*)*,i8*(i8*,i8*,i8*)**%r,align 8
%t=bitcast i8*%p to i8**
%u=load i8*,i8**%t,align 8
store i8*%u,i8**%g,align 8
%v=load i8*,i8**@_SMLZN9Substring4getcE,align 8
%w=bitcast i8**%d to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%w)
%x=bitcast i8**%e to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%x)
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%v,i8**%d,align 8
%y=call i8*@sml_alloc(i32 inreg 12)#0
%z=getelementptr inbounds i8,i8*%y,i64 -4
%A=bitcast i8*%z to i32*
store i32 1342177288,i32*%A,align 4
store i8*%y,i8**%e,align 8
%B=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%C=bitcast i8*%y to i8**
store i8*%B,i8**%C,align 8
%D=getelementptr inbounds i8,i8*%y,i64 8
%E=bitcast i8*%D to i32*
store i32 1,i32*%E,align 4
%F=call i8*@sml_alloc(i32 inreg 28)#0
%G=getelementptr inbounds i8,i8*%F,i64 -4
%H=bitcast i8*%G to i32*
store i32 1342177304,i32*%H,align 4
%I=load i8*,i8**%e,align 8
%J=bitcast i8*%F to i8**
store i8*%I,i8**%J,align 8
%K=getelementptr inbounds i8,i8*%F,i64 8
%L=bitcast i8*%K to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair8scanPairE_112 to void(...)*),void(...)**%L,align 8
%M=getelementptr inbounds i8,i8*%F,i64 16
%N=bitcast i8*%M to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair8scanPairE_112 to void(...)*),void(...)**%N,align 8
%O=getelementptr inbounds i8,i8*%F,i64 24
%P=bitcast i8*%O to i32*
store i32 -2147483647,i32*%P,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%w)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%x)
%Q=load i8*,i8**%f,align 8
%R=load i8*,i8**%g,align 8
store i8*null,i8**%f,align 8
store i8*null,i8**%g,align 8
%S=call fastcc i8*%s(i8*inreg%R,i8*inreg%F,i8*inreg%Q)
store i8*%S,i8**%f,align 8
%T=load i8*,i8**@_SMLZN9Substring4getcE,align 8
%U=bitcast i8**%b to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%U)
%V=bitcast i8**%c to i8*
call void@llvm.lifetime.start.p0i8(i64 8,i8*%V)
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%T,i8**%b,align 8
%W=call i8*@sml_alloc(i32 inreg 12)#0
%X=getelementptr inbounds i8,i8*%W,i64 -4
%Y=bitcast i8*%X to i32*
store i32 1342177288,i32*%Y,align 4
store i8*%W,i8**%c,align 8
%Z=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%aa=bitcast i8*%W to i8**
store i8*%Z,i8**%aa,align 8
%ab=getelementptr inbounds i8,i8*%W,i64 8
%ac=bitcast i8*%ab to i32*
store i32 1,i32*%ac,align 4
%ad=call i8*@sml_alloc(i32 inreg 28)#0
%ae=getelementptr inbounds i8,i8*%ad,i64 -4
%af=bitcast i8*%ae to i32*
store i32 1342177304,i32*%af,align 4
%ag=load i8*,i8**%c,align 8
%ah=bitcast i8*%ad to i8**
store i8*%ag,i8**%ah,align 8
%ai=getelementptr inbounds i8,i8*%ad,i64 8
%aj=bitcast i8*%ai to void(...)**
store void(...)*bitcast(i32(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair11endOfSourceE_115 to void(...)*),void(...)**%aj,align 8
%ak=getelementptr inbounds i8,i8*%ad,i64 16
%al=bitcast i8*%ak to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair11endOfSourceE_139 to void(...)*),void(...)**%al,align 8
%am=getelementptr inbounds i8,i8*%ad,i64 24
%an=bitcast i8*%am to i32*
store i32 -2147483647,i32*%an,align 4
call void@llvm.lifetime.end.p0i8(i64 8,i8*%U)
call void@llvm.lifetime.end.p0i8(i64 8,i8*%V)
%ao=load i8*,i8**%f,align 8
%ap=getelementptr inbounds i8,i8*%ao,i64 8
%aq=bitcast i8*%ap to i8**
%ar=load i8*,i8**%aq,align 8
%as=call fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair11endOfSourceE_139(i8*inreg%ag,i8*inreg%ar)
%at=bitcast i8*%as to i32*
%au=load i32,i32*%at,align 4
%av=icmp eq i32%au,0
br i1%av,label%aA,label%aw
aw:
%ax=bitcast i8**%f to i8***
%ay=load i8**,i8***%ax,align 8
%az=load i8*,i8**%ay,align 8
ret i8*%az
aA:
store i8*null,i8**%f,align 8
%aB=call i8*@sml_alloc(i32 inreg 60)#0
%aC=getelementptr inbounds i8,i8*%aB,i64 -4
%aD=bitcast i8*%aC to i32*
store i32 1342177336,i32*%aD,align 4
%aE=getelementptr inbounds i8,i8*%aB,i64 56
%aF=bitcast i8*%aE to i32*
store i32 1,i32*%aF,align 4
%aG=bitcast i8*%aB to i8**
store i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,i8*,i32}>,<{[4x i8],i32,i8*,i8*,i32}>*@d,i64 0,i32 2)to i8*),i8**%aG,align 8
call void@sml_raise(i8*inreg%aB)#1
unreachable
}
define internal fastcc i32@_SMLLN25SMLSharp__SQL__KeyValuePair4findE_122(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%b to i8**
%d=load i8*,i8**%c,align 8
%e=bitcast i8*%a to i8**
%f=load i8*,i8**%e,align 8
%g=tail call i32@sml_obj_equal(i8*inreg%d,i8*inreg%f)#0
ret i32%g
}
define fastcc i8*@_SMLFN25SMLSharp__SQL__KeyValuePair4findE(i8*inreg%a)#2 gc"smlsharp"{
l:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
store i8*%a,i8**%b,align 8
%f=load atomic i32,i32*@sml_check_flag unordered,align 4
%g=icmp eq i32%f,0
br i1%g,label%j,label%h
h:
call void@sml_check(i32 inreg%f)
%i=load i8*,i8**%b,align 8
br label%j
j:
%k=phi i8*[%i,%h],[%a,%l]
%m=getelementptr inbounds i8,i8*%k,i64 8
%n=bitcast i8*%m to i8**
%o=load i8*,i8**%n,align 8
store i8*%o,i8**%c,align 8
%p=call fastcc i8*@_SMLFN4List4findE(i32 inreg 1,i32 inreg 8)
%q=getelementptr inbounds i8,i8*%p,i64 16
%r=bitcast i8*%q to i8*(i8*,i8*)**
%s=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%r,align 8
%t=bitcast i8*%p to i8**
%u=load i8*,i8**%t,align 8
store i8*%u,i8**%d,align 8
%v=call i8*@sml_alloc(i32 inreg 12)#0
%w=getelementptr inbounds i8,i8*%v,i64 -4
%x=bitcast i8*%w to i32*
store i32 1342177288,i32*%x,align 4
store i8*%v,i8**%e,align 8
%y=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%z=bitcast i8*%v to i8**
store i8*%y,i8**%z,align 8
%A=getelementptr inbounds i8,i8*%v,i64 8
%B=bitcast i8*%A to i32*
store i32 1,i32*%B,align 4
%C=call i8*@sml_alloc(i32 inreg 28)#0
%D=getelementptr inbounds i8,i8*%C,i64 -4
%E=bitcast i8*%D to i32*
store i32 1342177304,i32*%E,align 4
%F=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%G=bitcast i8*%C to i8**
store i8*%F,i8**%G,align 8
%H=getelementptr inbounds i8,i8*%C,i64 8
%I=bitcast i8*%H to void(...)**
store void(...)*bitcast(i32(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair4findE_122 to void(...)*),void(...)**%I,align 8
%J=getelementptr inbounds i8,i8*%C,i64 16
%K=bitcast i8*%J to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair4findE_142 to void(...)*),void(...)**%K,align 8
%L=getelementptr inbounds i8,i8*%C,i64 24
%M=bitcast i8*%L to i32*
store i32 -2147483647,i32*%M,align 4
%N=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%O=call fastcc i8*%s(i8*inreg%N,i8*inreg%C)
%P=getelementptr inbounds i8,i8*%O,i64 16
%Q=bitcast i8*%P to i8*(i8*,i8*)**
%R=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%Q,align 8
%S=bitcast i8*%O to i8**
%T=load i8*,i8**%S,align 8
%U=bitcast i8**%b to i8***
%V=load i8**,i8***%U,align 8
store i8*null,i8**%b,align 8
%W=load i8*,i8**%V,align 8
%X=call fastcc i8*%R(i8*inreg%T,i8*inreg%W)
%Y=icmp eq i8*%X,null
br i1%Y,label%Z,label%aa
Z:
ret i8*null
aa:
%ab=bitcast i8*%X to i8**
%ac=load i8*,i8**%ab,align 8
%ad=getelementptr inbounds i8,i8*%ac,i64 8
%ae=bitcast i8*%ad to i8**
%af=load i8*,i8**%ae,align 8
store i8*%af,i8**%b,align 8
%ag=call i8*@sml_alloc(i32 inreg 12)#0
%ah=getelementptr inbounds i8,i8*%ag,i64 -4
%ai=bitcast i8*%ah to i32*
store i32 1342177288,i32*%ai,align 4
%aj=load i8*,i8**%b,align 8
%ak=bitcast i8*%ag to i8**
store i8*%aj,i8**%ak,align 8
%al=getelementptr inbounds i8,i8*%ag,i64 8
%am=bitcast i8*%al to i32*
store i32 1,i32*%am,align 4
ret i8*%ag
}
define internal fastcc i32@_SMLLN25SMLSharp__SQL__KeyValuePair10findExceptE_125(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%a to i8**
%d=load i8*,i8**%c,align 8
%e=tail call i32@sml_obj_equal(i8*inreg%b,i8*inreg%d)#0
ret i32%e
}
define internal fastcc i32@_SMLLN25SMLSharp__SQL__KeyValuePair10findExceptE_126(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%g=load atomic i32,i32*@sml_check_flag unordered,align 4
%h=icmp eq i32%g,0
br i1%h,label%i,label%k
i:
%j=bitcast i8*%b to i8**
br label%n
k:
call void@sml_check(i32 inreg%g)
%l=bitcast i8**%c to i8***
%m=load i8**,i8***%l,align 8
br label%n
n:
%o=phi i8**[%m,%k],[%j,%i]
%p=load i8*,i8**%o,align 8
store i8*%p,i8**%c,align 8
%q=call fastcc i8*@_SMLFN4List6existsE(i32 inreg 1,i32 inreg 8)
%r=getelementptr inbounds i8,i8*%q,i64 16
%s=bitcast i8*%r to i8*(i8*,i8*)**
%t=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%s,align 8
%u=bitcast i8*%q to i8**
%v=load i8*,i8**%u,align 8
store i8*%v,i8**%e,align 8
%w=call i8*@sml_alloc(i32 inreg 12)#0
%x=getelementptr inbounds i8,i8*%w,i64 -4
%y=bitcast i8*%x to i32*
store i32 1342177288,i32*%y,align 4
store i8*%w,i8**%f,align 8
%z=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%A=bitcast i8*%w to i8**
store i8*%z,i8**%A,align 8
%B=getelementptr inbounds i8,i8*%w,i64 8
%C=bitcast i8*%B to i32*
store i32 1,i32*%C,align 4
%D=call i8*@sml_alloc(i32 inreg 28)#0
%E=getelementptr inbounds i8,i8*%D,i64 -4
%F=bitcast i8*%E to i32*
store i32 1342177304,i32*%F,align 4
%G=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%H=bitcast i8*%D to i8**
store i8*%G,i8**%H,align 8
%I=getelementptr inbounds i8,i8*%D,i64 8
%J=bitcast i8*%I to void(...)**
store void(...)*bitcast(i32(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair10findExceptE_125 to void(...)*),void(...)**%J,align 8
%K=getelementptr inbounds i8,i8*%D,i64 16
%L=bitcast i8*%K to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair10findExceptE_144 to void(...)*),void(...)**%L,align 8
%M=getelementptr inbounds i8,i8*%D,i64 24
%N=bitcast i8*%M to i32*
store i32 -2147483647,i32*%N,align 4
%O=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%P=call fastcc i8*%t(i8*inreg%O,i8*inreg%D)
%Q=getelementptr inbounds i8,i8*%P,i64 16
%R=bitcast i8*%Q to i8*(i8*,i8*)**
%S=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%R,align 8
%T=bitcast i8*%P to i8**
%U=load i8*,i8**%T,align 8
%V=bitcast i8**%d to i8***
%W=load i8**,i8***%V,align 8
store i8*null,i8**%d,align 8
%X=load i8*,i8**%W,align 8
%Y=call fastcc i8*%S(i8*inreg%U,i8*inreg%X)
%Z=bitcast i8*%Y to i32*
%aa=load i32,i32*%Z,align 4
%ab=tail call fastcc i32@_SMLFN4Bool3notE(i32 inreg%aa)
ret i32%ab
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair10findExceptE_127(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%a,i8**%d,align 8
store i8*%b,i8**%c,align 8
%g=load atomic i32,i32*@sml_check_flag unordered,align 4
%h=icmp eq i32%g,0
br i1%h,label%j,label%i
i:
call void@sml_check(i32 inreg%g)
br label%j
j:
%k=call fastcc i8*@_SMLFN4List4findE(i32 inreg 1,i32 inreg 8)
%l=getelementptr inbounds i8,i8*%k,i64 16
%m=bitcast i8*%l to i8*(i8*,i8*)**
%n=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%m,align 8
%o=bitcast i8*%k to i8**
%p=load i8*,i8**%o,align 8
store i8*%p,i8**%e,align 8
%q=bitcast i8**%d to i8***
%r=load i8**,i8***%q,align 8
%s=load i8*,i8**%r,align 8
store i8*%s,i8**%d,align 8
%t=call i8*@sml_alloc(i32 inreg 12)#0
%u=getelementptr inbounds i8,i8*%t,i64 -4
%v=bitcast i8*%u to i32*
store i32 1342177288,i32*%v,align 4
store i8*%t,i8**%f,align 8
%w=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%x=bitcast i8*%t to i8**
store i8*%w,i8**%x,align 8
%y=getelementptr inbounds i8,i8*%t,i64 8
%z=bitcast i8*%y to i32*
store i32 1,i32*%z,align 4
%A=call i8*@sml_alloc(i32 inreg 28)#0
%B=getelementptr inbounds i8,i8*%A,i64 -4
%C=bitcast i8*%B to i32*
store i32 1342177304,i32*%C,align 4
%D=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%E=bitcast i8*%A to i8**
store i8*%D,i8**%E,align 8
%F=getelementptr inbounds i8,i8*%A,i64 8
%G=bitcast i8*%F to void(...)**
store void(...)*bitcast(i32(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair10findExceptE_126 to void(...)*),void(...)**%G,align 8
%H=getelementptr inbounds i8,i8*%A,i64 16
%I=bitcast i8*%H to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair10findExceptE_145 to void(...)*),void(...)**%I,align 8
%J=getelementptr inbounds i8,i8*%A,i64 24
%K=bitcast i8*%J to i32*
store i32 -2147483647,i32*%K,align 4
%L=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%M=call fastcc i8*%n(i8*inreg%L,i8*inreg%A)
%N=getelementptr inbounds i8,i8*%M,i64 16
%O=bitcast i8*%N to i8*(i8*,i8*)**
%P=load i8*(i8*,i8*)*,i8*(i8*,i8*)**%O,align 8
%Q=bitcast i8*%M to i8**
%R=load i8*,i8**%Q,align 8
%S=load i8*,i8**%c,align 8
%T=tail call fastcc i8*%P(i8*inreg%R,i8*inreg%S)
ret i8*%T
}
define fastcc i8*@_SMLFN25SMLSharp__SQL__KeyValuePair10findExceptE(i8*inreg%a)#4 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
%d=call i8*@sml_alloc(i32 inreg 12)#0
%e=getelementptr inbounds i8,i8*%d,i64 -4
%f=bitcast i8*%e to i32*
store i32 1342177288,i32*%f,align 4
store i8*%d,i8**%c,align 8
%g=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%h=bitcast i8*%d to i8**
store i8*%g,i8**%h,align 8
%i=getelementptr inbounds i8,i8*%d,i64 8
%j=bitcast i8*%i to i32*
store i32 1,i32*%j,align 4
%k=call i8*@sml_alloc(i32 inreg 28)#0
%l=getelementptr inbounds i8,i8*%k,i64 -4
%m=bitcast i8*%l to i32*
store i32 1342177304,i32*%m,align 4
%n=load i8*,i8**%c,align 8
%o=bitcast i8*%k to i8**
store i8*%n,i8**%o,align 8
%p=getelementptr inbounds i8,i8*%k,i64 8
%q=bitcast i8*%p to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair10findExceptE_127 to void(...)*),void(...)**%q,align 8
%r=getelementptr inbounds i8,i8*%k,i64 16
%s=bitcast i8*%r to void(...)**
store void(...)*bitcast(i8*(i8*,i8*)*@_SMLLN25SMLSharp__SQL__KeyValuePair10findExceptE_127 to void(...)*),void(...)**%s,align 8
%t=getelementptr inbounds i8,i8*%k,i64 24
%u=bitcast i8*%t to i32*
store i32 -2147483647,i32*%u,align 4
ret i8*%k
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair11endOfSourceE_139(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i32@_SMLLN25SMLSharp__SQL__KeyValuePair11endOfSourceE_115(i8*inreg%a,i8*inreg%b)
%d=tail call i8*@sml_alloc(i32 inreg 4)#0
%e=bitcast i8*%d to i32*
%f=getelementptr inbounds i8,i8*%d,i64 -4
%g=bitcast i8*%f to i32*
store i32 4,i32*%g,align 4
store i32%c,i32*%e,align 4
ret i8*%d
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair5parseE_141(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN25SMLSharp__SQL__KeyValuePair5parseE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair4findE_142(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=tail call fastcc i32@_SMLLN25SMLSharp__SQL__KeyValuePair4findE_122(i8*inreg%a,i8*inreg%b)
%d=tail call i8*@sml_alloc(i32 inreg 4)#0
%e=bitcast i8*%d to i32*
%f=getelementptr inbounds i8,i8*%d,i64 -4
%g=bitcast i8*%f to i32*
store i32 4,i32*%g,align 4
store i32%c,i32*%e,align 4
ret i8*%d
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair4findE_143(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN25SMLSharp__SQL__KeyValuePair4findE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair10findExceptE_144(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=bitcast i8*%a to i8**
%d=load i8*,i8**%c,align 8
%e=tail call i32@sml_obj_equal(i8*inreg%b,i8*inreg%d)#0
%f=tail call i8*@sml_alloc(i32 inreg 4)#0
%g=bitcast i8*%f to i32*
%h=getelementptr inbounds i8,i8*%f,i64 -4
%i=bitcast i8*%h to i32*
store i32 4,i32*%i,align 4
store i32%e,i32*%g,align 4
ret i8*%f
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair10findExceptE_145(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i32@_SMLLN25SMLSharp__SQL__KeyValuePair10findExceptE_126(i8*inreg%a,i8*inreg%b)
%d=tail call i8*@sml_alloc(i32 inreg 4)#0
%e=bitcast i8*%d to i32*
%f=getelementptr inbounds i8,i8*%d,i64 -4
%g=bitcast i8*%f to i32*
store i32 4,i32*%g,align 4
store i32%c,i32*%e,align 4
ret i8*%d
}
define internal fastcc i8*@_SMLLN25SMLSharp__SQL__KeyValuePair10findExceptE_146(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN25SMLSharp__SQL__KeyValuePair10findExceptE(i8*inreg%b)
ret i8*%c
}
declare void@llvm.memcpy.p0i8.p0i8.i32(i8*,i8*,i32,i1)#0
declare void@llvm.memset.p0i8.i32(i8*,i8,i32,i1)#0
declare void@llvm.lifetime.start.p0i8(i64,i8*)#0
declare void@llvm.lifetime.end.p0i8(i64,i8*)#0
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
attributes#4={nounwind uwtable}
