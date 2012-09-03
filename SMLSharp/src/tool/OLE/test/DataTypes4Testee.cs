using System;
using System.Runtime.InteropServices;

//[InterfaceTypeAttribute(ComInterfaceType.InterfaceIsDual)]
[ClassInterface(ClassInterfaceType.AutoDual)]
public class DataTypes4Testee
{
  // test for arity
  public void method_throw(){throw new Exception();}

  public DataTypes4Testee(){}
}
