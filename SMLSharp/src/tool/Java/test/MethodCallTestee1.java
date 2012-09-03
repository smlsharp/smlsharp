public class MethodCallTestee1
{
    // test of the number of parameters.
    public int f_v(){return 123;}
    public int f_i(int i){return i;}
    public int f_if(int i, float f){
        return i + ((new Float(f)).intValue() * 10);
    }
    public int f_dfi(double d, float f, int i){
        return
            (new Double(d)).intValue()
            + ((new Float(f)).intValue() * 10)
            + i * 100;
    }

    // test of overloaded method call.
    public String overload(boolean z){return "Z";}
    public String overload(byte b){return "B";}
    public String overload(char c){return "C";}
    public String overload(short s){return "S";}
    public String overload(int i){return "I";}
    public String overload(long j){return "J";}
    public String overload(float f){return "F";}
    public String overload(double d){return "D";}
    public String overload(Object o){return o.getClass().getName();}
    public String overload(){return "V";}

    // test of overridden method call.
    public String override(){return "parent";}

    public MethodCallTestee1(){}
}
