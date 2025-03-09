@sml_check_flag=external local_unnamed_addr global i32
@_SMLZ4Fail=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[22x i8]}><{[4x i8]zeroinitializer,i32 -2147483626,[22x i8]c"LibBase.Unimplemented\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[22x i8]}>,<{[4x i8],i32,[22x i8]}>*@a,i32 0,i32 0,i32 0),i32 8),i32 16,[4x i8]zeroinitializer,i32 1}>,align 8
@_SMLDL30=private constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@b,i32 0,i32 0,i32 0),i32 8)}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,[19x i8]}><{[4x i8]zeroinitializer,i32 -2147483629,[19x i8]c"LibBase.Impossible\00"}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[19x i8]}>,<{[4x i8],i32,[19x i8]}>*@c,i32 0,i32 0,i32 0),i32 8),i32 16,[4x i8]zeroinitializer,i32 1}>,align 8
@_SMLDL33=private constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@d,i32 0,i32 0,i32 0),i32 8)}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[17x i8]}><{[4x i8]zeroinitializer,i32 -2147483631,[17x i8]c"LibBase.NotFound\00"}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[17x i8]}>,<{[4x i8],i32,[17x i8]}>*@e,i32 0,i32 0,i32 0),i32 8),i32 0,[4x i8]zeroinitializer,i32 1}>,align 8
@_SMLDL36=private constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@f,i32 0,i32 0,i32 0),i32 8)}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,[43x i8]}><{[4x i8]zeroinitializer,i32 -2147483605,[43x i8]c"src/smlnj-lib/Util/lib-base.sml:21.10(499)\00"}>,align 8
@h=private unnamed_addr constant<{[4x i8],i32,[2x i8]}><{[4x i8]zeroinitializer,i32 -2147483646,[2x i8]c".\00"}>,align 8
@i=private unnamed_addr constant<{[4x i8],i32,[3x i8]}><{[4x i8]zeroinitializer,i32 -2147483645,[3x i8]c": \00"}>,align 8
@j=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLLLN7LibBase7failureE_40 to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN7LibBase7failureE_44 to void(...)*),i32 1}>,align 8
@k=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32,i32)*@_SMLFN7LibBase7failureE to void(...)*),void(...)*bitcast(i8*(i8*,i8*,i8*)*@_SMLLLN7LibBase7failureE_45 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN7LibBase13UnimplementedE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL30,i64 0,i32 2)to i8*)
@_SMLZN7LibBase10ImpossibleE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL33,i64 0,i32 2)to i8*)
@_SMLZN7LibBase8NotFoundE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL36,i64 0,i32 2)to i8*)
@_SMLZN7LibBase7failureE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@k,i64 0,i32 2)to i8*)
@_SML_ftab34dcc998b8dca612_lib_base=external global i8
@l=internal unnamed_addr global i1 false
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare i8*@_SMLFN10CharVector6concatE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_mainadbb5309e852b68c_CharVector()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_loadadbb5309e852b68c_CharVector(i8*)local_unnamed_addr
define private void@_SML_tabb34dcc998b8dca612_lib_base()#3{
unreachable
}
define void@_SML_load34dcc998b8dca612_lib_base(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@l,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@l,align 1
tail call void@_SML_loadadbb5309e852b68c_CharVector(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb34dcc998b8dca612_lib_base,i8*@_SML_ftab34dcc998b8dca612_lib_base,i8*null)#0
ret void
}
define void@_SML_main34dcc998b8dca612_lib_base()local_unnamed_addr#2 gc"smlsharp"{
tail call void@_SML_mainadbb5309e852b68c_CharVector()#2
ret void
}
define internal fastcc i8*@_SMLLLN7LibBase7failureE_40(i8*inreg%a)#4 gc"smlsharp"{
m:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
%d=alloca i8*,align 8
%e=alloca i8*,align 8
%f=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
call void@llvm.gcroot(i8**%d,i8*null)#0
call void@llvm.gcroot(i8**%e,i8*null)#0
call void@llvm.gcroot(i8**%f,i8*null)#0
store i8*%a,i8**%b,align 8
%g=load atomic i32,i32*@sml_check_flag unordered,align 4
%h=icmp eq i32%g,0
br i1%h,label%k,label%i
i:
call void@sml_check(i32 inreg%g)
%j=load i8*,i8**%b,align 8
br label%k
k:
%l=phi i8*[%j,%i],[%a,%m]
%n=bitcast i8*%l to i8**
%o=load i8*,i8**%n,align 8
store i8*%o,i8**%b,align 8
%p=load i8*,i8**@_SMLZ4Fail,align 8
store i8*%p,i8**%c,align 8
%q=getelementptr inbounds i8,i8*%l,i64 8
%r=bitcast i8*%q to i8**
%s=load i8*,i8**%r,align 8
store i8*%s,i8**%d,align 8
%t=getelementptr inbounds i8,i8*%l,i64 16
%u=bitcast i8*%t to i8**
%v=load i8*,i8**%u,align 8
store i8*%v,i8**%e,align 8
%w=call i8*@sml_alloc(i32 inreg 20)#0
%x=getelementptr inbounds i8,i8*%w,i64 -4
%y=bitcast i8*%x to i32*
store i32 1342177296,i32*%y,align 4
store i8*%w,i8**%f,align 8
%z=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%A=bitcast i8*%w to i8**
store i8*%z,i8**%A,align 8
%B=getelementptr inbounds i8,i8*%w,i64 8
%C=bitcast i8*%B to i8**
store i8*null,i8**%C,align 8
%D=getelementptr inbounds i8,i8*%w,i64 16
%E=bitcast i8*%D to i32*
store i32 3,i32*%E,align 4
%F=call i8*@sml_alloc(i32 inreg 20)#0
%G=getelementptr inbounds i8,i8*%F,i64 -4
%H=bitcast i8*%G to i32*
store i32 1342177296,i32*%H,align 4
store i8*%F,i8**%e,align 8
%I=bitcast i8*%F to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[3x i8]}>,<{[4x i8],i32,[3x i8]}>*@i,i64 0,i32 2,i64 0),i8**%I,align 8
%J=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%K=getelementptr inbounds i8,i8*%F,i64 8
%L=bitcast i8*%K to i8**
store i8*%J,i8**%L,align 8
%M=getelementptr inbounds i8,i8*%F,i64 16
%N=bitcast i8*%M to i32*
store i32 3,i32*%N,align 4
%O=call i8*@sml_alloc(i32 inreg 20)#0
%P=getelementptr inbounds i8,i8*%O,i64 -4
%Q=bitcast i8*%P to i32*
store i32 1342177296,i32*%Q,align 4
store i8*%O,i8**%f,align 8
%R=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%S=bitcast i8*%O to i8**
store i8*%R,i8**%S,align 8
%T=load i8*,i8**%e,align 8
store i8*null,i8**%e,align 8
%U=getelementptr inbounds i8,i8*%O,i64 8
%V=bitcast i8*%U to i8**
store i8*%T,i8**%V,align 8
%W=getelementptr inbounds i8,i8*%O,i64 16
%X=bitcast i8*%W to i32*
store i32 3,i32*%X,align 4
%Y=call i8*@sml_alloc(i32 inreg 20)#0
%Z=getelementptr inbounds i8,i8*%Y,i64 -4
%aa=bitcast i8*%Z to i32*
store i32 1342177296,i32*%aa,align 4
store i8*%Y,i8**%b,align 8
%ab=bitcast i8*%Y to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[2x i8]}>,<{[4x i8],i32,[2x i8]}>*@h,i64 0,i32 2,i64 0),i8**%ab,align 8
%ac=load i8*,i8**%f,align 8
store i8*null,i8**%f,align 8
%ad=getelementptr inbounds i8,i8*%Y,i64 8
%ae=bitcast i8*%ad to i8**
store i8*%ac,i8**%ae,align 8
%af=getelementptr inbounds i8,i8*%Y,i64 16
%ag=bitcast i8*%af to i32*
store i32 3,i32*%ag,align 4
%ah=call i8*@sml_alloc(i32 inreg 20)#0
%ai=getelementptr inbounds i8,i8*%ah,i64 -4
%aj=bitcast i8*%ai to i32*
store i32 1342177296,i32*%aj,align 4
%ak=load i8*,i8**%d,align 8
store i8*null,i8**%d,align 8
%al=bitcast i8*%ah to i8**
store i8*%ak,i8**%al,align 8
%am=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%an=getelementptr inbounds i8,i8*%ah,i64 8
%ao=bitcast i8*%an to i8**
store i8*%am,i8**%ao,align 8
%ap=getelementptr inbounds i8,i8*%ah,i64 16
%aq=bitcast i8*%ap to i32*
store i32 3,i32*%aq,align 4
%ar=call fastcc i8*@_SMLFN10CharVector6concatE(i8*inreg%ah)
store i8*%ar,i8**%b,align 8
%as=call i8*@sml_alloc(i32 inreg 28)#0
%at=getelementptr inbounds i8,i8*%as,i64 -4
%au=bitcast i8*%at to i32*
store i32 1342177304,i32*%au,align 4
store i8*%as,i8**%d,align 8
%av=load i8*,i8**%c,align 8
store i8*null,i8**%c,align 8
%aw=bitcast i8*%as to i8**
store i8*%av,i8**%aw,align 8
%ax=getelementptr inbounds i8,i8*%as,i64 8
%ay=bitcast i8*%ax to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[43x i8]}>,<{[4x i8],i32,[43x i8]}>*@g,i64 0,i32 2,i64 0),i8**%ay,align 8
%az=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%aA=getelementptr inbounds i8,i8*%as,i64 16
%aB=bitcast i8*%aA to i8**
store i8*%az,i8**%aB,align 8
%aC=getelementptr inbounds i8,i8*%as,i64 24
%aD=bitcast i8*%aC to i32*
store i32 7,i32*%aD,align 4
%aE=call i8*@sml_alloc(i32 inreg 60)#0
%aF=getelementptr inbounds i8,i8*%aE,i64 -4
%aG=bitcast i8*%aF to i32*
store i32 1342177336,i32*%aG,align 4
%aH=getelementptr inbounds i8,i8*%aE,i64 56
%aI=bitcast i8*%aH to i32*
store i32 1,i32*%aI,align 4
%aJ=load i8*,i8**%d,align 8
%aK=bitcast i8*%aE to i8**
store i8*%aJ,i8**%aK,align 8
call void@sml_raise(i8*inreg%aE)#1
unreachable
}
define fastcc i8*@_SMLFN7LibBase7failureE(i32 inreg%a,i32 inreg%b)#5 gc"smlsharp"{
ret i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@j,i64 0,i32 2)to i8*)
}
define internal fastcc i8*@_SMLLLN7LibBase7failureE_44(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLLLN7LibBase7failureE_40(i8*inreg%b)
unreachable
}
define internal fastcc i8*@_SMLLLN7LibBase7failureE_45(i8*inreg%a,i8*inreg%b,i8*inreg%c)#5 gc"smlsharp"{
ret i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@j,i64 0,i32 2)to i8*)
}
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
attributes#4={noreturn uwtable}
attributes#5={nounwind uwtable}
