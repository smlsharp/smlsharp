using System;
using System.Runtime.InteropServices;

//[InterfaceTypeAttribute(ComInterfaceType.InterfaceIsDual)]
[ClassInterface(ClassInterfaceType.AutoDual)]
public class DataTypes3Testee
{
  // test for arity
  public int method_II_I(int x, int y){return x + y;}
  public int method_ID_I(int x, double y){return x + (int)y;}
  public int method_DI_I(double x, int y){return (int)x + y;}
  public int method_DIB_I(double x, int y, byte z){return (int)x + y + z;}
  public int method_BDI_I(byte x, double y, int z){return x + (int)y + z;}
  public int method_IBD_I(int x, byte y, double z){return x + y + (int)z;}

  // test for co-arity
  public void method_V_V(){}
  public void method_I_V(int x){}
  public void method_II_V(int x, int y){}
  
  public DataTypes3Testee(){}
}
