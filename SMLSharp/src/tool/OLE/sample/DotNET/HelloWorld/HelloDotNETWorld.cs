using System.Runtime.InteropServices;

[InterfaceTypeAttribute(ComInterfaceType.InterfaceIsDual)]
public interface IHelloDotNETWorld
{
    string greeting(string yourName);
}

[ClassInterface(ClassInterfaceType.None)]
public class HelloDotNETWorld : IHelloDotNETWorld
{
    public HelloDotNETWorld(){
        System.Console.WriteLine("I am a .NET object.");
    }

    public string greeting(string yourName)
    {
        return "Hello, " + yourName + " !";
    }
};
