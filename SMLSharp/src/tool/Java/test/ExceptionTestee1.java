public class ExceptionTestee1
{
    public int doThrow(int x, boolean raise)
        throws ExceptionTestee1Exception
    {
        if(raise){
            throw new ExceptionTestee1Exception();
        }
        return x;
    }
    public ExceptionTestee1(){}
}
