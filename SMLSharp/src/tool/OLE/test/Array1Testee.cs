using System;
using System.Runtime.InteropServices;

//[InterfaceTypeAttribute(ComInterfaceType.InterfaceIsDual)]
[ClassInterface(ClassInterfaceType.AutoDual)]
public class Array1Testee
{
  int[] _zero = new int[0];
  public int[] zero(){return _zero;}

  // single-dimensional array
  int[] _single = new int[3];
  public int[] single(){return _single;}

  // multi-dimensional array
  int[,] _multi2 = new int[2,3];
  public int[,] multi2(){return _multi2;}

  // 3-dimensional array
  int[,,] _multi3 = new int[10,20,30];
  public int[,,] multi3(){return _multi3;}

  /* MS COMinterop does not support marshalling of jagged array.
   * The method 'jagged' is not included in the type library which TlbExp.exe
   * generates from Array1Testee.dll.
   */
  // jagged array
  int[][] _jagged = new int[2][]{new int[3], new int[3]};
  public int[][] jagged(){return _jagged;}

  public Array1Testee()
  {
      _single[0] = 0;
      _single[1] = 1;
      _single[2] = 2;

      _multi2[0, 0] = 0;
      _multi2[0, 1] = 1;
      _multi2[0, 2] = 2;
      _multi2[1, 0] = 3;
      _multi2[1, 1] = 4;
      _multi2[1, 2] = 5;

      int n = 0;
      for(int i1 = 0; i1 < 10; i1++){
          for(int i2 = 0; i2 < 20; i2++){
              for(int i3 = 0; i3 < 30; i3++){
                  _multi3[i1, i2, i3] = n;
                  n++;
              }
          }
      }
  }
}
