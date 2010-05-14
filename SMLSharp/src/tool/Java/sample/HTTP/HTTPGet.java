import java.net.*;
import java.io.*;

public class HTTPGet
{
    static PrintStream out = System.out;

    public static void main(String args[])
    {
        try{
            URL url = new URL("http://www.pllab.riec.tohoku.ac.jp/smlsharp/");
            URLConnection connection = url.openConnection();
            InputStream inStream = connection.getInputStream();
            BufferedReader input =
                new BufferedReader(new InputStreamReader(inStream));

            while (input.ready()){
                out.println(input.readLine());
            }
        }
        catch(IOException e){
            out.println(e.toString());
        }
        catch(Exception e){
            e.printStackTrace();
        }
    }
}
