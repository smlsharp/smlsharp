import java.net.URL;
import java.net.URLConnection;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;

public class HTTPGet
{
    public static void main(String args[])
    {
        try{
            URL url = new URL("http://www.pllab.riec.tohoku.ac.jp/smlsharp/");
            URLConnection connection = url.openConnection();
            InputStream inStream = connection.getInputStream();
            BufferedReader input =
                new BufferedReader(new InputStreamReader(inStream));

            while (input.ready()){
                System.out.println(input.readLine());
            }
        }
        catch(IOException e){
            System.out.println(e.toString());
        }
        catch(Exception e){
            e.printStackTrace();
        }
    }
}
