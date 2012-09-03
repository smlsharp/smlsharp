import java.sql.*;

/**
 * Sample code to test JDBC with CSV JDBC driver.
 * <pre>
 * $ javac CSVJDBCTest.java
 * $ java -cp "./csvjdbc.jar;." CSVJDBCTest
 * </pre>
 */
public class CSVJDBCTest
{
    public static void main(String[] args)
        throws Exception
    {
        Class.forName("org.relique.jdbc.csv.CsvDriver");

        String URL = "jdbc:relique:csv:./tables";
        Connection conn = DriverManager.getConnection(URL);
        Statement stmt = conn.createStatement();
        ResultSet results =
                  stmt.executeQuery("SELECT NAME, TYPE FROM languages");

        while (results.next())
        {
            System.out.println("NAME= "
                               + results.getString("NAME")
                               + "   TYPE= "
                               + results.getString("TYPE"));
        }

        results.close();
        stmt.close();
        conn.close();
    }
}
