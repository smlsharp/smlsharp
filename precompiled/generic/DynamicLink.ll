@sml_check_flag=external local_unnamed_addr global i32
@a=private unnamed_addr constant<{[4x i8],i32,[18x i8]}><{[4x i8]zeroinitializer,i32 -2147483630,[18x i8]c"DynamicLink.Error\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,i32,[4x i8],i32}><{[4x i8]zeroinitializer,i32 -805306352,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,[18x i8]}>,<{[4x i8],i32,[18x i8]}>*@a,i32 0,i32 0,i32 0),i32 8),i32 16,[4x i8]zeroinitializer,i32 1}>,align 8
@_SMLDL50=private constant<{[4x i8],i32,i8*}><{[4x i8]zeroinitializer,i32 -1879048184,i8*getelementptr inbounds(i8,i8*getelementptr inbounds(<{[4x i8],i32,i8*,i32,[4x i8],i32}>,<{[4x i8],i32,i8*,i32,[4x i8],i32}>*@b,i32 0,i32 0,i32 0),i32 8)}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32)*@_SMLFN11DynamicLink7defaultE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11DynamicLink7defaultE_76 to void(...)*),i32 -2147483647}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i32)*@_SMLFN11DynamicLink4nextE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11DynamicLink4nextE_77 to void(...)*),i32 -2147483647}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,[41x i8]}><{[4x i8]zeroinitializer,i32 -2147483607,[41x i8]c"src/ffi/main/DynamicLink.sml:98.19(2677)\00"}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN11DynamicLink7dlopen_GE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11DynamicLink7dlopen_GE_78 to void(...)*),i32 -2147483647}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN11DynamicLink6dlopenE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11DynamicLink6dlopenE_79 to void(...)*),i32 -2147483647}>,align 8
@h=private unnamed_addr constant<{[4x i8],i32,[42x i8]}><{[4x i8]zeroinitializer,i32 -2147483606,[42x i8]c"src/ffi/main/DynamicLink.sml:107.17(2849)\00"}>,align 8
@i=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(void(i64)*@_SMLFN11DynamicLink7dlcloseE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11DynamicLink7dlcloseE_80 to void(...)*),i32 -2147483647}>,align 8
@j=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN11DynamicLink6dlsym_GE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11DynamicLink6dlsym_GE_81 to void(...)*),i32 -2147483647}>,align 8
@k=private unnamed_addr constant<{[4x i8],i32,[42x i8]}><{[4x i8]zeroinitializer,i32 -2147483606,[42x i8]c"src/ffi/main/DynamicLink.sml:121.26(3256)\00"}>,align 8
@l=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(void(...)*(i8*)*@_SMLFN11DynamicLink5dlsymE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN11DynamicLink5dlsymE_82 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN11DynamicLink5ErrorE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL50,i64 0,i32 2)to i8*)
@_SMLZN11DynamicLink7defaultE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*)
@_SMLZN11DynamicLink4nextE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@d,i64 0,i32 2)to i8*)
@_SMLZN11DynamicLink6dlopenE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@g,i64 0,i32 2)to i8*)
@_SMLZN11DynamicLink7dlopen_GE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@f,i64 0,i32 2)to i8*)
@_SMLZN11DynamicLink5dlsymE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@l,i64 0,i32 2)to i8*)
@_SMLZN11DynamicLink6dlsym_GE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@j,i64 0,i32 2)to i8*)
@_SMLZN11DynamicLink7dlcloseE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@i,i64 0,i32 2)to i8*)
@_SML_ftab82bd5aec591c098a_DynamicLink=external global i8
@m=internal unnamed_addr global i1 false
@n=internal unnamed_addr global i1 false,align 8
@o=internal unnamed_addr global i32 0,align 8
@p=internal unnamed_addr global i32 0,align 8
@q=internal unnamed_addr global i32 0,align 8
@r=internal unnamed_addr global i32 0,align 8
@s=internal unnamed_addr global i8*null,align 8
@t=internal unnamed_addr global i8*null,align 8
declare i32@dlclose(i8*)local_unnamed_addr
declare i8*@dlerror()local_unnamed_addr
declare i8*@dlopen(i8*,i32)local_unnamed_addr
declare i8*@dlsym(i8*,i8*)local_unnamed_addr
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@prim_const_RTLD_DEFAULT()local_unnamed_addr
declare i32@prim_const_RTLD_GLOBAL()local_unnamed_addr
declare i32@prim_const_RTLD_LAZY()local_unnamed_addr
declare i32@prim_const_RTLD_LOCAL()local_unnamed_addr
declare i8*@prim_const_RTLD_NEXT()local_unnamed_addr
declare i32@prim_const_RTLD_NOW()local_unnamed_addr
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_enter()local_unnamed_addr#0
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_leave()local_unnamed_addr#0
declare i32@sml_personality(...)#0
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare i8*@sml_unsave_exn(i8*inreg)local_unnamed_addr#0
declare i8*@_SMLFN16SMLSharp__Runtime7str__newE(i64 inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main00d884c96265bfea_SMLSharp_Runtime()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load00d884c96265bfea_SMLSharp_Runtime(i8*)local_unnamed_addr
define private void@_SML_tabb82bd5aec591c098a_DynamicLink()#3{
unreachable
}
define void@_SML_load82bd5aec591c098a_DynamicLink(i8*%a)local_unnamed_addr#0{
%b=load i1,i1*@m,align 1
br i1%b,label%c,label%d
c:
ret void
d:
store i1 true,i1*@m,align 1
tail call void@_SML_load00d884c96265bfea_SMLSharp_Runtime(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb82bd5aec591c098a_DynamicLink,i8*@_SML_ftab82bd5aec591c098a_DynamicLink,i8*null)#0
ret void
}
define void@_SML_main82bd5aec591c098a_DynamicLink()local_unnamed_addr#2 gc"smlsharp"{
tail call void@_SML_main00d884c96265bfea_SMLSharp_Runtime()#2
ret void
}
define fastcc i8*@_SMLFN11DynamicLink7defaultE(i32 inreg%a)#2 gc"smlsharp"{
%b=load atomic i32,i32*@sml_check_flag unordered,align 4
%c=icmp eq i32%b,0
br i1%c,label%e,label%d
d:
tail call void@sml_check(i32 inreg%b)
br label%e
e:
%f=load i1,i1*@n,align 8
br i1%f,label%n,label%g
g:
%h=tail call i32@prim_const_RTLD_LAZY()
store i32%h,i32*@o,align 8
%i=tail call i32@prim_const_RTLD_NOW()
store i32%i,i32*@p,align 8
%j=tail call i32@prim_const_RTLD_LOCAL()
store i32%j,i32*@q,align 8
%k=tail call i32@prim_const_RTLD_GLOBAL()
store i32%k,i32*@r,align 8
%l=tail call i8*@prim_const_RTLD_DEFAULT()
store i8*%l,i8**@s,align 8
%m=tail call i8*@prim_const_RTLD_NEXT()
store i8*%m,i8**@t,align 8
store i1 true,i1*@n,align 8
br label%n
n:
%o=load i8*,i8**@s,align 8
ret i8*%o
}
define fastcc i8*@_SMLFN11DynamicLink4nextE(i32 inreg%a)#2 gc"smlsharp"{
%b=load atomic i32,i32*@sml_check_flag unordered,align 4
%c=icmp eq i32%b,0
br i1%c,label%e,label%d
d:
tail call void@sml_check(i32 inreg%b)
br label%e
e:
%f=load i1,i1*@n,align 8
br i1%f,label%g,label%i
g:
%h=load i8*,i8**@t,align 8
br label%p
i:
%j=tail call i32@prim_const_RTLD_LAZY()
store i32%j,i32*@o,align 8
%k=tail call i32@prim_const_RTLD_NOW()
store i32%k,i32*@p,align 8
%l=tail call i32@prim_const_RTLD_LOCAL()
store i32%l,i32*@q,align 8
%m=tail call i32@prim_const_RTLD_GLOBAL()
store i32%m,i32*@r,align 8
%n=tail call i8*@prim_const_RTLD_DEFAULT()
store i8*%n,i8**@s,align 8
%o=tail call i8*@prim_const_RTLD_NEXT()
store i8*%o,i8**@t,align 8
store i1 true,i1*@n,align 8
br label%p
p:
%q=phi i8*[%h,%g],[%o,%i]
ret i8*%q
}
define fastcc i8*@_SMLFN11DynamicLink7dlopen_GE(i8*inreg%a)#2 gc"smlsharp"personality i32(...)*@sml_personality{
j:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
%d=load atomic i32,i32*@sml_check_flag unordered,align 4
%e=icmp eq i32%d,0
br i1%e,label%h,label%f
f:
call void@sml_check(i32 inreg%d)
%g=load i8*,i8**%b,align 8
br label%h
h:
%i=phi i8*[%g,%f],[%a,%j]
%k=bitcast i8*%i to i8**
%l=load i8*,i8**%k,align 8
store i8*%l,i8**%b,align 8
%m=getelementptr inbounds i8,i8*%i,i64 8
%n=bitcast i8*%m to i32*
%o=load i32,i32*%n,align 4
%p=getelementptr inbounds i8,i8*%i,i64 12
%q=bitcast i8*%p to i32*
%r=load i32,i32*%q,align 4
%s=load i1,i1*@n,align 8
br i1%s,label%B,label%t
t:
%u=call i32@prim_const_RTLD_LAZY()
store i32%u,i32*@o,align 8
%v=call i32@prim_const_RTLD_NOW()
store i32%v,i32*@p,align 8
%w=call i32@prim_const_RTLD_LOCAL()
store i32%w,i32*@q,align 8
%x=call i32@prim_const_RTLD_GLOBAL()
store i32%x,i32*@r,align 8
%y=call i8*@prim_const_RTLD_DEFAULT()
store i8*%y,i8**@s,align 8
%z=call i8*@prim_const_RTLD_NEXT()
store i8*%z,i8**@t,align 8
store i1 true,i1*@n,align 8
%A=load i8*,i8**%b,align 8
br label%B
B:
%C=phi i8*[%l,%h],[%A,%t]
%D=icmp eq i32%o,0
%E=load i32,i32*@r,align 8
%F=load i32,i32*@q,align 8
%G=select i1%D,i32%E,i32%F
%H=icmp eq i32%r,0
%I=load i32,i32*@o,align 8
%J=load i32,i32*@p,align 8
%K=select i1%H,i32%I,i32%J
%L=add nsw i32%K,%G
call void@sml_leave()#0
%M=invoke i8*@dlopen(i8*%C,i32%L)
to label%N unwind label%am
N:
call void@sml_enter()#0
store i8*null,i8**%b,align 8
%O=icmp eq i8*%M,null
br i1%O,label%P,label%al
P:
%Q=call i8*@dlerror()
%R=ptrtoint i8*%Q to i64
%S=call fastcc i8*@_SMLFN16SMLSharp__Runtime7str__newE(i64 inreg%R)
store i8*%S,i8**%b,align 8
%T=call i8*@sml_alloc(i32 inreg 28)#0
%U=getelementptr inbounds i8,i8*%T,i64 -4
%V=bitcast i8*%U to i32*
store i32 1342177304,i32*%V,align 4
store i8*%T,i8**%c,align 8
%W=bitcast i8*%T to i8**
store i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL50,i64 0,i32 2)to i8*),i8**%W,align 8
%X=getelementptr inbounds i8,i8*%T,i64 8
%Y=bitcast i8*%X to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[41x i8]}>,<{[4x i8],i32,[41x i8]}>*@e,i64 0,i32 2,i64 0),i8**%Y,align 8
%Z=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%aa=getelementptr inbounds i8,i8*%T,i64 16
%ab=bitcast i8*%aa to i8**
store i8*%Z,i8**%ab,align 8
%ac=getelementptr inbounds i8,i8*%T,i64 24
%ad=bitcast i8*%ac to i32*
store i32 7,i32*%ad,align 4
%ae=call i8*@sml_alloc(i32 inreg 60)#0
%af=getelementptr inbounds i8,i8*%ae,i64 -4
%ag=bitcast i8*%af to i32*
store i32 1342177336,i32*%ag,align 4
%ah=getelementptr inbounds i8,i8*%ae,i64 56
%ai=bitcast i8*%ah to i32*
store i32 1,i32*%ai,align 4
%aj=load i8*,i8**%c,align 8
%ak=bitcast i8*%ae to i8**
store i8*%aj,i8**%ak,align 8
call void@sml_raise(i8*inreg%ae)#1
unreachable
al:
ret i8*%M
am:
%an=landingpad{i8*,i8*}
cleanup
%ao=extractvalue{i8*,i8*}%an,1
call void@sml_enter()#0
%ap=call i8*@sml_unsave_exn(i8*inreg%ao)#0
resume{i8*,i8*}%an
}
define fastcc i8*@_SMLFN11DynamicLink6dlopenE(i8*inreg%a)#2 gc"smlsharp"{
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
%g=call i8*@sml_alloc(i32 inreg 20)#0
%h=getelementptr inbounds i8,i8*%g,i64 -4
%i=bitcast i8*%h to i32*
store i32 1342177296,i32*%i,align 4
%j=load i8*,i8**%b,align 8
%k=bitcast i8*%g to i8**
store i8*%j,i8**%k,align 8
%l=getelementptr inbounds i8,i8*%g,i64 8
%m=bitcast i8*%l to i32*
store i32 1,i32*%m,align 4
%n=getelementptr inbounds i8,i8*%g,i64 12
%o=bitcast i8*%n to i32*
store i32 0,i32*%o,align 4
%p=getelementptr inbounds i8,i8*%g,i64 16
%q=bitcast i8*%p to i32*
store i32 1,i32*%q,align 4
%r=tail call fastcc i8*@_SMLFN11DynamicLink7dlopen_GE(i8*inreg%g)
ret i8*%r
}
define fastcc void@_SMLFN11DynamicLink7dlcloseE(i64 inreg%a)#2 gc"smlsharp"personality i32(...)*@sml_personality{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
%d=load atomic i32,i32*@sml_check_flag unordered,align 4
%e=icmp eq i32%d,0
br i1%e,label%g,label%f
f:
call void@sml_check(i32 inreg%d)
br label%g
g:
%h=inttoptr i64%a to i8*
call void@sml_leave()#0
%i=invoke i32@dlclose(i8*%h)
to label%j unwind label%l
j:
call void@sml_enter()#0
%k=icmp sgt i32%i,-1
br i1%k,label%L,label%p
l:
%m=landingpad{i8*,i8*}
cleanup
%n=extractvalue{i8*,i8*}%m,1
call void@sml_enter()#0
%o=call i8*@sml_unsave_exn(i8*inreg%n)#0
resume{i8*,i8*}%m
p:
%q=call i8*@dlerror()
%r=ptrtoint i8*%q to i64
%s=call fastcc i8*@_SMLFN16SMLSharp__Runtime7str__newE(i64 inreg%r)
store i8*%s,i8**%b,align 8
%t=call i8*@sml_alloc(i32 inreg 28)#0
%u=getelementptr inbounds i8,i8*%t,i64 -4
%v=bitcast i8*%u to i32*
store i32 1342177304,i32*%v,align 4
store i8*%t,i8**%c,align 8
%w=bitcast i8*%t to i8**
store i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL50,i64 0,i32 2)to i8*),i8**%w,align 8
%x=getelementptr inbounds i8,i8*%t,i64 8
%y=bitcast i8*%x to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[42x i8]}>,<{[4x i8],i32,[42x i8]}>*@h,i64 0,i32 2,i64 0),i8**%y,align 8
%z=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%A=getelementptr inbounds i8,i8*%t,i64 16
%B=bitcast i8*%A to i8**
store i8*%z,i8**%B,align 8
%C=getelementptr inbounds i8,i8*%t,i64 24
%D=bitcast i8*%C to i32*
store i32 7,i32*%D,align 4
%E=call i8*@sml_alloc(i32 inreg 60)#0
%F=getelementptr inbounds i8,i8*%E,i64 -4
%G=bitcast i8*%F to i32*
store i32 1342177336,i32*%G,align 4
%H=getelementptr inbounds i8,i8*%E,i64 56
%I=bitcast i8*%H to i32*
store i32 1,i32*%I,align 4
%J=load i8*,i8**%c,align 8
%K=bitcast i8*%E to i8**
store i8*%J,i8**%K,align 8
call void@sml_raise(i8*inreg%E)#1
unreachable
L:
ret void
}
define fastcc i8*@_SMLFN11DynamicLink6dlsym_GE(i8*inreg%a)#2 gc"smlsharp"personality i32(...)*@sml_personality{
j:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
%d=load atomic i32,i32*@sml_check_flag unordered,align 4
%e=icmp eq i32%d,0
br i1%e,label%h,label%f
f:
call void@sml_check(i32 inreg%d)
%g=load i8*,i8**%b,align 8
br label%h
h:
%i=phi i8*[%g,%f],[%a,%j]
%k=bitcast i8*%i to i8**
%l=load i8*,i8**%k,align 8
%m=getelementptr inbounds i8,i8*%i,i64 8
%n=bitcast i8*%m to i8**
%o=load i8*,i8**%n,align 8
store i8*%o,i8**%b,align 8
%p=call i8*@dlerror()
%q=load i8*,i8**%b,align 8
call void@sml_leave()#0
%r=invoke i8*@dlsym(i8*%l,i8*%q)
to label%s unwind label%T
s:
call void@sml_enter()#0
store i8*null,i8**%b,align 8
%t=icmp eq i8*%r,null
br i1%t,label%u,label%x
u:
%v=call i8*@dlerror()
%w=icmp eq i8*%v,null
br i1%w,label%x,label%y
x:
ret i8*%r
y:
%z=ptrtoint i8*%v to i64
%A=call fastcc i8*@_SMLFN16SMLSharp__Runtime7str__newE(i64 inreg%z)
store i8*%A,i8**%b,align 8
%B=call i8*@sml_alloc(i32 inreg 28)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177304,i32*%D,align 4
store i8*%B,i8**%c,align 8
%E=bitcast i8*%B to i8**
store i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL50,i64 0,i32 2)to i8*),i8**%E,align 8
%F=getelementptr inbounds i8,i8*%B,i64 8
%G=bitcast i8*%F to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[42x i8]}>,<{[4x i8],i32,[42x i8]}>*@k,i64 0,i32 2,i64 0),i8**%G,align 8
%H=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%I=getelementptr inbounds i8,i8*%B,i64 16
%J=bitcast i8*%I to i8**
store i8*%H,i8**%J,align 8
%K=getelementptr inbounds i8,i8*%B,i64 24
%L=bitcast i8*%K to i32*
store i32 7,i32*%L,align 4
%M=call i8*@sml_alloc(i32 inreg 60)#0
%N=getelementptr inbounds i8,i8*%M,i64 -4
%O=bitcast i8*%N to i32*
store i32 1342177336,i32*%O,align 4
%P=getelementptr inbounds i8,i8*%M,i64 56
%Q=bitcast i8*%P to i32*
store i32 1,i32*%Q,align 4
%R=load i8*,i8**%c,align 8
%S=bitcast i8*%M to i8**
store i8*%R,i8**%S,align 8
call void@sml_raise(i8*inreg%M)#1
unreachable
T:
%U=landingpad{i8*,i8*}
cleanup
%V=extractvalue{i8*,i8*}%U,1
call void@sml_enter()#0
%W=call i8*@sml_unsave_exn(i8*inreg%V)#0
resume{i8*,i8*}%U
}
define fastcc void(...)*@_SMLFN11DynamicLink5dlsymE(i8*inreg%a)#2 gc"smlsharp"personality i32(...)*@sml_personality{
j:
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
%d=load atomic i32,i32*@sml_check_flag unordered,align 4
%e=icmp eq i32%d,0
br i1%e,label%h,label%f
f:
call void@sml_check(i32 inreg%d)
%g=load i8*,i8**%b,align 8
br label%h
h:
%i=phi i8*[%g,%f],[%a,%j]
%k=bitcast i8*%i to i8**
%l=load i8*,i8**%k,align 8
%m=getelementptr inbounds i8,i8*%i,i64 8
%n=bitcast i8*%m to i8**
%o=load i8*,i8**%n,align 8
store i8*%o,i8**%b,align 8
%p=call i8*@dlerror()
%q=load i8*,i8**%b,align 8
call void@sml_leave()#0
%r=invoke i8*@dlsym(i8*%l,i8*%q)
to label%s unwind label%U
s:
call void@sml_enter()#0
store i8*null,i8**%b,align 8
%t=icmp eq i8*%r,null
br i1%t,label%u,label%S
u:
%v=call i8*@dlerror()
%w=icmp eq i8*%v,null
br i1%w,label%S,label%x
x:
%y=ptrtoint i8*%v to i64
%z=call fastcc i8*@_SMLFN16SMLSharp__Runtime7str__newE(i64 inreg%y)
store i8*%z,i8**%b,align 8
%A=call i8*@sml_alloc(i32 inreg 28)#0
%B=getelementptr inbounds i8,i8*%A,i64 -4
%C=bitcast i8*%B to i32*
store i32 1342177304,i32*%C,align 4
store i8*%A,i8**%c,align 8
%D=bitcast i8*%A to i8**
store i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*}>,<{[4x i8],i32,i8*}>*@_SMLDL50,i64 0,i32 2)to i8*),i8**%D,align 8
%E=getelementptr inbounds i8,i8*%A,i64 8
%F=bitcast i8*%E to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[42x i8]}>,<{[4x i8],i32,[42x i8]}>*@k,i64 0,i32 2,i64 0),i8**%F,align 8
%G=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%H=getelementptr inbounds i8,i8*%A,i64 16
%I=bitcast i8*%H to i8**
store i8*%G,i8**%I,align 8
%J=getelementptr inbounds i8,i8*%A,i64 24
%K=bitcast i8*%J to i32*
store i32 7,i32*%K,align 4
%L=call i8*@sml_alloc(i32 inreg 60)#0
%M=getelementptr inbounds i8,i8*%L,i64 -4
%N=bitcast i8*%M to i32*
store i32 1342177336,i32*%N,align 4
%O=getelementptr inbounds i8,i8*%L,i64 56
%P=bitcast i8*%O to i32*
store i32 1,i32*%P,align 4
%Q=load i8*,i8**%c,align 8
%R=bitcast i8*%L to i8**
store i8*%Q,i8**%R,align 8
call void@sml_raise(i8*inreg%L)#1
unreachable
S:
%T=bitcast i8*%r to void(...)*
ret void(...)*%T
U:
%V=landingpad{i8*,i8*}
cleanup
%W=extractvalue{i8*,i8*}%V,1
call void@sml_enter()#0
%X=call i8*@sml_unsave_exn(i8*inreg%W)#0
resume{i8*,i8*}%V
}
define internal fastcc i8*@_SMLLLN11DynamicLink7defaultE_76(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11DynamicLink7defaultE(i32 inreg undef)
%d=tail call i8*@sml_alloc(i32 inreg 8)#0
%e=getelementptr inbounds i8,i8*%d,i64 -4
%f=bitcast i8*%e to i32*
store i32 8,i32*%f,align 4
%g=bitcast i8*%d to i8**
store i8*%c,i8**%g,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLLLN11DynamicLink4nextE_77(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11DynamicLink4nextE(i32 inreg undef)
%d=tail call i8*@sml_alloc(i32 inreg 8)#0
%e=getelementptr inbounds i8,i8*%d,i64 -4
%f=bitcast i8*%e to i32*
store i32 8,i32*%f,align 4
%g=bitcast i8*%d to i8**
store i8*%c,i8**%g,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLLLN11DynamicLink7dlopen_GE_78(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11DynamicLink7dlopen_GE(i8*inreg%b)
%d=tail call i8*@sml_alloc(i32 inreg 8)#0
%e=getelementptr inbounds i8,i8*%d,i64 -4
%f=bitcast i8*%e to i32*
store i32 8,i32*%f,align 4
%g=bitcast i8*%d to i8**
store i8*%c,i8**%g,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLLLN11DynamicLink6dlopenE_79(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11DynamicLink6dlopenE(i8*inreg%b)
%d=tail call i8*@sml_alloc(i32 inreg 8)#0
%e=getelementptr inbounds i8,i8*%d,i64 -4
%f=bitcast i8*%e to i32*
store i32 8,i32*%f,align 4
%g=bitcast i8*%d to i8**
store i8*%c,i8**%g,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLLLN11DynamicLink7dlcloseE_80(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=bitcast i8*%b to i64*
%d=load i64,i64*%c,align 4
tail call fastcc void@_SMLFN11DynamicLink7dlcloseE(i64 inreg%d)
%e=tail call i8*@sml_alloc(i32 inreg 4)#0
%f=bitcast i8*%e to i32*
%g=getelementptr inbounds i8,i8*%e,i64 -4
%h=bitcast i8*%g to i32*
store i32 4,i32*%h,align 4
store i32 0,i32*%f,align 4
ret i8*%e
}
define internal fastcc i8*@_SMLLLN11DynamicLink6dlsym_GE_81(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN11DynamicLink6dlsym_GE(i8*inreg%b)
%d=tail call i8*@sml_alloc(i32 inreg 8)#0
%e=getelementptr inbounds i8,i8*%d,i64 -4
%f=bitcast i8*%e to i32*
store i32 8,i32*%f,align 4
%g=bitcast i8*%d to i8**
store i8*%c,i8**%g,align 8
ret i8*%d
}
define internal fastcc i8*@_SMLLLN11DynamicLink5dlsymE_82(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc void(...)*@_SMLFN11DynamicLink5dlsymE(i8*inreg%b)
%d=tail call i8*@sml_alloc(i32 inreg 8)#0
%e=getelementptr inbounds i8,i8*%d,i64 -4
%f=bitcast i8*%e to i32*
store i32 8,i32*%f,align 4
%g=bitcast i8*%d to void(...)**
store void(...)*%c,void(...)**%g,align 8
ret i8*%d
}
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
