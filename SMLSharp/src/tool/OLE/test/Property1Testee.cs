using System;
using System.Runtime.InteropServices;

//[InterfaceTypeAttribute(ComInterfaceType.InterfaceIsDual)]
[ClassInterface(ClassInterfaceType.AutoDual)]
public class Property1Testee
{
  private int field_I_RW = 1;
  private int field_I_R = 2;
  private int field_I_W = 3;

  private object field_O_RW = new object();

  // test for property accessor
  public int property_I_RW {
      get {return field_I_RW;}
      set {field_I_RW = value;}
  }

  public int property_I_R {
      get {return field_I_R;}
  }

  public void set_I_R(int value){
      field_I_R = value;
  }

  public int property_I_W {
      set {field_I_W = value;}
  }

  public int get_I_W(){
      return field_I_W;
  }

  // property of object reference type.
  public object property_O_RW {
      get {return field_O_RW;}
      set {field_O_RW = value;}
  }

  public Property1Testee(){}
}
