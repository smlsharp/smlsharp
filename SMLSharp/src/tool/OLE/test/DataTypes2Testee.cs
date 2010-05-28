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
public class DataTypes2Testee
{
  public byte[] method_byte(byte[] x){return x;}
  public sbyte[] method_sbyte(sbyte[] x){return x;}
  public short[] method_short(short[] x){return x;}
  public ushort[] method_ushort(ushort[] x){return x;}
  public int[] method_int(int[] x){return x;}
  public uint[] method_uint(uint[] x){return x;}
  public long[] method_long(long[] x){return x;}
  public ulong[] method_ulong(ulong[] x){return x;}
  public float[] method_float(float[] x){return x;}
  public double[] method_double(double[] x){return x;}
  public decimal[] method_decimal(decimal[] x){return x;}
  public char[] method_char(char[] x){return x;}
  public string[] method_string(string[] x){return x;}
  public bool[] method_bool(bool[] x){return x;}
  public object[] method_object(object[] x){return x;}
    
  public byte sub_byte(byte[] x, int i){return x[i];}
  public sbyte sub_sbyte(sbyte[] x, int i){return x[i];}
  public short sub_short(short[] x, int i){return x[i];}
  public ushort sub_ushort(ushort[] x, int i){return x[i];}
  public int sub_int(int[] x, int i){return x[i];}
  public uint sub_uint(uint[] x, int i){return x[i];}
  public long sub_long(long[] x, int i){return x[i];}
  public ulong sub_ulong(ulong[] x, int i){return x[i];}
  public float sub_float(float[] x, int i){return x[i];}
  public double sub_double(double[] x, int i){return x[i];}
  public decimal sub_decimal(decimal[] x, int i){return x[i];}
  public char sub_char(char[] x, int i){return x[i];}
  public string sub_string(string[] x, int i){return x[i];}
  public bool sub_bool(bool[] x, int i){return x[i];}
  public object sub_object(object[] x, int i){return x[i];}
    
  public DataTypes2Testee(){}
}
