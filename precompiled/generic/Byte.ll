@sml_check_flag=external local_unnamed_addr global i32
@_SMLZ9Subscript=external unnamed_addr constant i8*
@_SMLZ4Size=external unnamed_addr constant i8*
@a=private unnamed_addr constant<{[4x i8],i32,[35x i8]}><{[4x i8]zeroinitializer,i32 -2147483613,[35x i8]c"src/basis/main/Byte.sml:32.18(805)\00"}>,align 8
@b=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN4Byte13bytesToStringE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN4Byte13bytesToStringE_48 to void(...)*),i32 -2147483647}>,align 8
@c=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN4Byte13stringToBytesE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN4Byte13stringToBytesE_49 to void(...)*),i32 -2147483647}>,align 8
@d=private unnamed_addr constant<{[4x i8],i32,[36x i8]}><{[4x i8]zeroinitializer,i32 -2147483612,[36x i8]c"src/basis/main/Byte.sml:52.18(1357)\00"}>,align 8
@e=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN4Byte15unpackStringVecE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN4Byte15unpackStringVecE_50 to void(...)*),i32 -2147483647}>,align 8
@f=private unnamed_addr constant<{[4x i8],i32,[36x i8]}><{[4x i8]zeroinitializer,i32 -2147483612,[36x i8]c"src/basis/main/Byte.sml:62.18(1652)\00"}>,align 8
@g=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(i8*(i8*)*@_SMLFN4Byte12unpackStringE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN4Byte12unpackStringE_51 to void(...)*),i32 -2147483647}>,align 8
@h=private unnamed_addr constant<{[4x i8],i32,[36x i8]}><{[4x i8]zeroinitializer,i32 -2147483612,[36x i8]c"src/basis/main/Byte.sml:76.19(2129)\00"}>,align 8
@i=private unnamed_addr constant<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}><{[4x i8]zeroinitializer,i32 -805306344,i8*null,void(...)*bitcast(void(i8*)*@_SMLFN4Byte10packStringE to void(...)*),void(...)*bitcast(i8*(i8*,i8*)*@_SMLLLN4Byte10packStringE_52 to void(...)*),i32 -2147483647}>,align 8
@_SMLZN4Byte13bytesToStringE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@b,i64 0,i32 2)to i8*)
@_SMLZN4Byte13stringToBytesE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@c,i64 0,i32 2)to i8*)
@_SMLZN4Byte15unpackStringVecE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@e,i64 0,i32 2)to i8*)
@_SMLZN4Byte12unpackStringE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@g,i64 0,i32 2)to i8*)
@_SMLZN4Byte10packStringE=local_unnamed_addr constant i8*bitcast(i8**getelementptr inbounds(<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>,<{[4x i8],i32,i8*,void(...)*,void(...)*,i32}>*@i,i64 0,i32 2)to i8*)
@_SML_ftab07023b79a356e238_Byte=external global i8
@j=private unnamed_addr global i8 0
declare void@llvm.gcroot(i8**,i8*)#0
declare i8*@sml_alloc(i32 inreg)local_unnamed_addr#0
declare void@sml_check(i32 inreg)local_unnamed_addr
declare void@sml_gcroot(i8*,void()*,i8*,i8*)local_unnamed_addr#0
declare void@sml_raise(i8*inreg)local_unnamed_addr#1
declare i8*@_SMLFN15Word8ArraySlice4baseE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN16Word8VectorSlice4baseE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare i8*@_SMLFN9Substring4baseE(i8*inreg)local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main145db56e6796da5b_Substring()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_main78563455976a8f16_Word8VectorSlice()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_maind090c7e00210ea66_Word8ArraySlice()local_unnamed_addr#2 gc"smlsharp"
declare void@_SML_load145db56e6796da5b_Substring(i8*)local_unnamed_addr
declare void@_SML_load78563455976a8f16_Word8VectorSlice(i8*)local_unnamed_addr
declare void@_SML_loadd090c7e00210ea66_Word8ArraySlice(i8*)local_unnamed_addr
define private void@_SML_tabb07023b79a356e238_Byte()#3{
unreachable
}
define void@_SML_load07023b79a356e238_Byte(i8*%a)local_unnamed_addr#0{
%b=load i8,i8*@j,align 1
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 1,i8*@j,align 1
tail call void@_SML_load145db56e6796da5b_Substring(i8*%a)#0
tail call void@_SML_load78563455976a8f16_Word8VectorSlice(i8*%a)#0
tail call void@_SML_loadd090c7e00210ea66_Word8ArraySlice(i8*%a)#0
tail call void@sml_gcroot(i8*%a,void()*@_SML_tabb07023b79a356e238_Byte,i8*@_SML_ftab07023b79a356e238_Byte,i8*null)#0
ret void
}
define void@_SML_main07023b79a356e238_Byte()local_unnamed_addr#2 gc"smlsharp"{
%a=load i8,i8*@j,align 1
%b=and i8%a,2
%c=icmp eq i8%b,0
br i1%c,label%e,label%d
d:
ret void
e:
store i8 3,i8*@j,align 1
tail call void@_SML_main145db56e6796da5b_Substring()#2
tail call void@_SML_main78563455976a8f16_Word8VectorSlice()#2
tail call void@_SML_maind090c7e00210ea66_Word8ArraySlice()#2
br label%d
}
define fastcc i8*@_SMLFN4Byte13bytesToStringE(i8*inreg%a)#2 gc"smlsharp"{
%b=alloca i8*,align 8
%c=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
call void@llvm.gcroot(i8**%c,i8*null)#0
store i8*%a,i8**%b,align 8
%d=getelementptr inbounds i8,i8*%a,i64 -4
%e=bitcast i8*%d to i32*
%f=load i32,i32*%e,align 4
%g=and i32%f,268435455
%h=icmp eq i32%g,268435455
br i1%h,label%q,label%i
i:
%j=add nuw nsw i32%g,1
%k=call i8*@sml_alloc(i32 inreg%j)#0
%l=getelementptr inbounds i8,i8*%k,i64 -4
%m=bitcast i8*%l to i32*
store i32%j,i32*%m,align 4
%n=zext i32%g to i64
%o=getelementptr inbounds i8,i8*%k,i64%n
store i8 0,i8*%o,align 1
%p=load i8*,i8**%b,align 8
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%k,i8*%p,i32%g,i1 false)
ret i8*%k
q:
%r=load i8*,i8**@_SMLZ4Size,align 8
store i8*%r,i8**%b,align 8
%s=call i8*@sml_alloc(i32 inreg 20)#0
%t=getelementptr inbounds i8,i8*%s,i64 -4
%u=bitcast i8*%t to i32*
store i32 1342177296,i32*%u,align 4
store i8*%s,i8**%c,align 8
%v=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%w=bitcast i8*%s to i8**
store i8*%v,i8**%w,align 8
%x=getelementptr inbounds i8,i8*%s,i64 8
%y=bitcast i8*%x to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[35x i8]}>,<{[4x i8],i32,[35x i8]}>*@a,i64 0,i32 2,i64 0),i8**%y,align 8
%z=getelementptr inbounds i8,i8*%s,i64 16
%A=bitcast i8*%z to i32*
store i32 3,i32*%A,align 4
%B=call i8*@sml_alloc(i32 inreg 60)#0
%C=getelementptr inbounds i8,i8*%B,i64 -4
%D=bitcast i8*%C to i32*
store i32 1342177336,i32*%D,align 4
%E=getelementptr inbounds i8,i8*%B,i64 56
%F=bitcast i8*%E to i32*
store i32 1,i32*%F,align 4
%G=load i8*,i8**%c,align 8
%H=bitcast i8*%B to i8**
store i8*%G,i8**%H,align 8
call void@sml_raise(i8*inreg%B)#1
unreachable
}
define fastcc i8*@_SMLFN4Byte13stringToBytesE(i8*inreg%a)#4 gc"smlsharp"{
%b=alloca i8*,align 8
call void@llvm.gcroot(i8**%b,i8*null)#0
store i8*%a,i8**%b,align 8
%c=getelementptr inbounds i8,i8*%a,i64 -4
%d=bitcast i8*%c to i32*
%e=load i32,i32*%d,align 4
%f=and i32%e,268435455
%g=add nsw i32%f,-1
%h=call i8*@sml_alloc(i32 inreg%g)#0
%i=getelementptr inbounds i8,i8*%h,i64 -4
%j=bitcast i8*%i to i32*
store i32%g,i32*%j,align 4
%k=load i8*,i8**%b,align 8
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%h,i8*%k,i32%g,i1 false)
ret i8*%h
}
define fastcc i8*@_SMLFN4Byte15unpackStringVecE(i8*inreg%a)#2 gc"smlsharp"{
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
store i8*null,i8**%b,align 8
%k=call fastcc i8*@_SMLFN16Word8VectorSlice4baseE(i8*inreg%i)
%l=bitcast i8*%k to i8**
%m=load i8*,i8**%l,align 8
store i8*%m,i8**%b,align 8
%n=getelementptr inbounds i8,i8*%k,i64 12
%o=bitcast i8*%n to i32*
%p=load i32,i32*%o,align 4
%q=icmp ugt i32%p,268435454
br i1%q,label%E,label%r
r:
%s=getelementptr inbounds i8,i8*%k,i64 8
%t=bitcast i8*%s to i32*
%u=load i32,i32*%t,align 4
%v=add nsw i32%p,1
%w=call i8*@sml_alloc(i32 inreg%v)#0
%x=getelementptr inbounds i8,i8*%w,i64 -4
%y=bitcast i8*%x to i32*
store i32%v,i32*%y,align 4
%z=sext i32%p to i64
%A=getelementptr inbounds i8,i8*%w,i64%z
store i8 0,i8*%A,align 1
%B=load i8*,i8**%b,align 8
%C=sext i32%u to i64
%D=getelementptr inbounds i8,i8*%B,i64%C
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%w,i8*%D,i32%p,i1 false)
ret i8*%w
E:
%F=load i8*,i8**@_SMLZ4Size,align 8
store i8*%F,i8**%b,align 8
%G=call i8*@sml_alloc(i32 inreg 20)#0
%H=getelementptr inbounds i8,i8*%G,i64 -4
%I=bitcast i8*%H to i32*
store i32 1342177296,i32*%I,align 4
store i8*%G,i8**%c,align 8
%J=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%K=bitcast i8*%G to i8**
store i8*%J,i8**%K,align 8
%L=getelementptr inbounds i8,i8*%G,i64 8
%M=bitcast i8*%L to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[36x i8]}>,<{[4x i8],i32,[36x i8]}>*@d,i64 0,i32 2,i64 0),i8**%M,align 8
%N=getelementptr inbounds i8,i8*%G,i64 16
%O=bitcast i8*%N to i32*
store i32 3,i32*%O,align 4
%P=call i8*@sml_alloc(i32 inreg 60)#0
%Q=getelementptr inbounds i8,i8*%P,i64 -4
%R=bitcast i8*%Q to i32*
store i32 1342177336,i32*%R,align 4
%S=getelementptr inbounds i8,i8*%P,i64 56
%T=bitcast i8*%S to i32*
store i32 1,i32*%T,align 4
%U=load i8*,i8**%c,align 8
%V=bitcast i8*%P to i8**
store i8*%U,i8**%V,align 8
call void@sml_raise(i8*inreg%P)#1
unreachable
}
define fastcc i8*@_SMLFN4Byte12unpackStringE(i8*inreg%a)#2 gc"smlsharp"{
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
store i8*null,i8**%b,align 8
%k=call fastcc i8*@_SMLFN15Word8ArraySlice4baseE(i8*inreg%i)
%l=bitcast i8*%k to i8**
%m=load i8*,i8**%l,align 8
store i8*%m,i8**%b,align 8
%n=getelementptr inbounds i8,i8*%k,i64 12
%o=bitcast i8*%n to i32*
%p=load i32,i32*%o,align 4
%q=icmp ugt i32%p,268435454
br i1%q,label%E,label%r
r:
%s=getelementptr inbounds i8,i8*%k,i64 8
%t=bitcast i8*%s to i32*
%u=load i32,i32*%t,align 4
%v=add nsw i32%p,1
%w=call i8*@sml_alloc(i32 inreg%v)#0
%x=getelementptr inbounds i8,i8*%w,i64 -4
%y=bitcast i8*%x to i32*
store i32%v,i32*%y,align 4
%z=sext i32%p to i64
%A=getelementptr inbounds i8,i8*%w,i64%z
store i8 0,i8*%A,align 1
%B=load i8*,i8**%b,align 8
%C=sext i32%u to i64
%D=getelementptr inbounds i8,i8*%B,i64%C
call void@llvm.memcpy.p0i8.p0i8.i32(i8*%w,i8*%D,i32%p,i1 false)
ret i8*%w
E:
%F=load i8*,i8**@_SMLZ4Size,align 8
store i8*%F,i8**%b,align 8
%G=call i8*@sml_alloc(i32 inreg 20)#0
%H=getelementptr inbounds i8,i8*%G,i64 -4
%I=bitcast i8*%H to i32*
store i32 1342177296,i32*%I,align 4
store i8*%G,i8**%c,align 8
%J=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%K=bitcast i8*%G to i8**
store i8*%J,i8**%K,align 8
%L=getelementptr inbounds i8,i8*%G,i64 8
%M=bitcast i8*%L to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[36x i8]}>,<{[4x i8],i32,[36x i8]}>*@f,i64 0,i32 2,i64 0),i8**%M,align 8
%N=getelementptr inbounds i8,i8*%G,i64 16
%O=bitcast i8*%N to i32*
store i32 3,i32*%O,align 4
%P=call i8*@sml_alloc(i32 inreg 60)#0
%Q=getelementptr inbounds i8,i8*%P,i64 -4
%R=bitcast i8*%Q to i32*
store i32 1342177336,i32*%R,align 4
%S=getelementptr inbounds i8,i8*%P,i64 56
%T=bitcast i8*%S to i32*
store i32 1,i32*%T,align 4
%U=load i8*,i8**%c,align 8
%V=bitcast i8*%P to i8**
store i8*%U,i8**%V,align 8
call void@sml_raise(i8*inreg%P)#1
unreachable
}
define fastcc void@_SMLFN4Byte10packStringE(i8*inreg%a)#2 gc"smlsharp"{
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
%p=getelementptr inbounds i8,i8*%i,i64 16
%q=bitcast i8*%p to i8**
%r=load i8*,i8**%q,align 8
%s=call fastcc i8*@_SMLFN9Substring4baseE(i8*inreg%r)
%t=getelementptr inbounds i8,i8*%s,i64 12
%u=bitcast i8*%t to i32*
%v=load i32,i32*%u,align 4
%w=load i8*,i8**%b,align 8
%x=getelementptr inbounds i8,i8*%w,i64 -4
%y=bitcast i8*%x to i32*
%z=load i32,i32*%y,align 4
%A=and i32%z,268435455
%B=icmp ult i32%A,%o
%C=sub nsw i32%A,%o
%D=icmp slt i32%C,%v
%E=or i1%B,%D
br i1%E,label%P,label%F
F:
%G=getelementptr inbounds i8,i8*%s,i64 8
%H=bitcast i8*%G to i32*
%I=load i32,i32*%H,align 4
%J=bitcast i8*%s to i8**
%K=load i8*,i8**%J,align 8
%L=sext i32%o to i64
%M=getelementptr inbounds i8,i8*%w,i64%L
%N=sext i32%I to i64
%O=getelementptr inbounds i8,i8*%K,i64%N
call void@llvm.memmove.p0i8.p0i8.i32(i8*%M,i8*%O,i32%v,i1 false)
ret void
P:
%Q=load i8*,i8**@_SMLZ9Subscript,align 8
store i8*%Q,i8**%b,align 8
%R=call i8*@sml_alloc(i32 inreg 20)#0
%S=getelementptr inbounds i8,i8*%R,i64 -4
%T=bitcast i8*%S to i32*
store i32 1342177296,i32*%T,align 4
store i8*%R,i8**%c,align 8
%U=load i8*,i8**%b,align 8
store i8*null,i8**%b,align 8
%V=bitcast i8*%R to i8**
store i8*%U,i8**%V,align 8
%W=getelementptr inbounds i8,i8*%R,i64 8
%X=bitcast i8*%W to i8**
store i8*getelementptr inbounds(<{[4x i8],i32,[36x i8]}>,<{[4x i8],i32,[36x i8]}>*@h,i64 0,i32 2,i64 0),i8**%X,align 8
%Y=getelementptr inbounds i8,i8*%R,i64 16
%Z=bitcast i8*%Y to i32*
store i32 3,i32*%Z,align 4
%aa=call i8*@sml_alloc(i32 inreg 60)#0
%ab=getelementptr inbounds i8,i8*%aa,i64 -4
%ac=bitcast i8*%ab to i32*
store i32 1342177336,i32*%ac,align 4
%ad=getelementptr inbounds i8,i8*%aa,i64 56
%ae=bitcast i8*%ad to i32*
store i32 1,i32*%ae,align 4
%af=load i8*,i8**%c,align 8
%ag=bitcast i8*%aa to i8**
store i8*%af,i8**%ag,align 8
call void@sml_raise(i8*inreg%aa)#1
unreachable
}
define internal fastcc i8*@_SMLLLN4Byte13bytesToStringE_48(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN4Byte13bytesToStringE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN4Byte13stringToBytesE_49(i8*inreg%a,i8*inreg%b)#4 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN4Byte13stringToBytesE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN4Byte15unpackStringVecE_50(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN4Byte15unpackStringVecE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN4Byte12unpackStringE_51(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
%c=tail call fastcc i8*@_SMLFN4Byte12unpackStringE(i8*inreg%b)
ret i8*%c
}
define internal fastcc i8*@_SMLLLN4Byte10packStringE_52(i8*inreg%a,i8*inreg%b)#2 gc"smlsharp"{
tail call fastcc void@_SMLFN4Byte10packStringE(i8*inreg%b)
%c=tail call i8*@sml_alloc(i32 inreg 4)#0
%d=bitcast i8*%c to i32*
%e=getelementptr inbounds i8,i8*%c,i64 -4
%f=bitcast i8*%e to i32*
store i32 4,i32*%f,align 4
store i32 0,i32*%d,align 4
ret i8*%c
}
declare void@llvm.memmove.p0i8.p0i8.i32(i8*,i8*,i32,i1)#0
declare void@llvm.memcpy.p0i8.p0i8.i32(i8*,i8*,i32,i1)#0
attributes#0={nounwind}
attributes#1={noreturn}
attributes#2={uwtable}
attributes#3={noreturn nounwind}
attributes#4={nounwind uwtable}
