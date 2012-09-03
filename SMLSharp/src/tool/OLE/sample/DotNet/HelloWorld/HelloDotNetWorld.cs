namespace SMLSharp{
    
    using System.Runtime.InteropServices;

    [ClassInterface(ClassInterfaceType.AutoDual)]
    public class HelloDotNetWorld
    {
        public HelloDotNetWorld(){
            System.Console.WriteLine("I am a .Net object.");
        }

        public string greeting(string yourName)
        {
            return "Hello .Net world, " + yourName + " !";
        }
    }

};
