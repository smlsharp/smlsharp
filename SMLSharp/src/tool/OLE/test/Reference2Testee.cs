using System;
using System.Runtime.InteropServices;

//[InterfaceTypeAttribute(ComInterfaceType.InterfaceIsDual)]
[ClassInterface(ClassInterfaceType.AutoDual)]
public class Reference2Testee
{
  public byte method_byte(byte src, ref byte dst)
  {byte tmp = dst;dst = src; return tmp;}
  public sbyte method_sbyte(sbyte src, ref sbyte dst)
  {sbyte tmp = dst;dst = src; return tmp;}
  public short method_short(short src, ref short dst)
  {short tmp = dst;dst = src; return tmp;}
  public ushort method_ushort(ushort src, ref ushort dst)
  {ushort tmp = dst;dst = src; return tmp;}
  public int method_int(int src, ref int dst)
  {int tmp = dst;dst = src; return tmp;}
  public uint method_uint(uint src, ref uint dst)
  {uint tmp = dst;dst = src; return tmp;}
  public long method_long(long src, ref long dst)
  {long tmp = dst;dst = src; return tmp;}
  public ulong method_ulong(ulong src, ref ulong dst)
  {ulong tmp = dst;dst = src; return tmp;}
  public float method_float(float src, ref float dst)
  {float tmp = dst;dst = src; return tmp;}
  public double method_double(double src, ref double dst)
  {double tmp = dst;dst = src; return tmp;}
  public decimal method_decimal(decimal src, ref decimal dst)
  {decimal tmp = dst;dst = src; return tmp;}
  public char method_char(char src, ref char dst)
  {char tmp = dst;dst = src; return tmp;}
  public string method_string(string src, ref string dst)
  {string tmp = dst;dst = src; return tmp;}
  public bool method_bool(bool src, ref bool dst)
  {bool tmp = dst;dst = src; return tmp;}
  public object method_object(object src, ref object dst)
  {object tmp = dst;dst = src; return tmp;}

  public Reference2Testee(){}
}
