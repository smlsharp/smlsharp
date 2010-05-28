using System;
using System.Runtime.InteropServices;

/**
 * Built-in datatypes of C#:
 * byte
 * sbyte
 * short
 * ushort
 * int
 * uint
 * long
 * ulong
 * float
 * double
 * decimal
 * char
 * string
 * bool
 * object
 *
 * Reference:
 * http://msdn.microsoft.com/en-us/library/cs7y5x0x(VS.80).aspx
 * http://msdn.microsoft.com/en-us/library/4xwz0t37(VS.80).aspx
 */
//[InterfaceTypeAttribute(ComInterfaceType.InterfaceIsDual)]
[ClassInterface(ClassInterfaceType.AutoDual)]
public class DataTypes1Testee
{
  public byte method_byte(byte x){return x;}
  public sbyte method_sbyte(sbyte x){return x;}
  public short method_short(short x){return x;}
  public ushort method_ushort(ushort x){return x;}
  public int method_int(int x){return x;}
  public uint method_uint(uint x){return x;}
  public long method_long(long x){return x;}
  public ulong method_ulong(ulong x){return x;}
  public float method_float(float x){return x;}
  public double method_double(double x){return x;}
  public decimal method_decimal(decimal x){return x;}
  public char method_char(char x){return x;}
  public string method_string(string x){return x;}
  public bool method_bool(bool x){return x;}
  public object method_object(object x){return x;}
    
  public string toString_byte(byte x){return x.ToString();}
  public string toString_sbyte(sbyte x){return x.ToString();}
  public string toString_short(short x){return x.ToString();}
  public string toString_ushort(ushort x){return x.ToString();}
  public string toString_int(int x){return x.ToString();}
  public string toString_uint(uint x){return x.ToString();}
  public string toString_long(long x){return x.ToString();}
  public string toString_ulong(ulong x){return x.ToString();}
  public string toString_float(float x){return x.ToString();}
  public string toString_double(double x){return x.ToString();}
  public string toString_decimal(decimal x){return x.ToString();}
  public string toString_char(char x){return x.ToString();}
  public string toString_string(string x){return x.ToString();}
  public string toString_bool(bool x){return x.ToString();}
  public string toString_object(object x){return x.ToString();}
    
  public byte fromString_byte(string x){return Byte.Parse(x);}
  public sbyte fromString_sbyte(string x){return SByte.Parse(x);}
  public short fromString_short(string x){return Int16.Parse(x);}
  public ushort fromString_ushort(string x){return UInt16.Parse(x);}
  public int fromString_int(string x){return Int32.Parse(x);}
  public uint fromString_uint(string x){return UInt32.Parse(x);}
  public long fromString_long(string x){return Int64.Parse(x);}
  public ulong fromString_ulong(string x){return UInt64.Parse(x);}
  public float fromString_float(string x){return Single.Parse(x);}
  public double fromString_double(string x){return Double.Parse(x);}
  public decimal fromString_decimal(string x){return Decimal.Parse(x);}
  public char fromString_char(string x){return Char.Parse(x);}
  public string fromString_string(string x){return x;}
  public bool fromString_bool(string x){return Boolean.Parse(x);}
    //  public object fromString_object(string x){return object.Parse(x);}
    
  public DataTypes1Testee(){}
}
