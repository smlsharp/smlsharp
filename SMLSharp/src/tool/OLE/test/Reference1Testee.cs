using System;
using System.Runtime.InteropServices;

//[InterfaceTypeAttribute(ComInterfaceType.InterfaceIsDual)]
[ClassInterface(ClassInterfaceType.AutoDual)]
public class Reference1Testee
{
    public object returnNull(){return null;}

    public bool isNullObject(object x){return null == x;}

    public void addIntRef(int x, ref int result){result = x + result;}

    public void mulIntOut(int x, int y, out int result){result = x * y;}

    // Check what happens if two ref arguments is the same reference.
    public void divIntRef(int x, ref int y, ref int result){result = x / y;}

    public void copyObjectRef(object src, ref object dst){dst = src;}

    public void copyObjectRef2(object src, ref object dst1, ref object dst2)
    {
        // update only dst1.
        dst1 = src;
    }

  public Reference1Testee(){}
}
