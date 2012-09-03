public class ArrayTestee1
{
    //////////

    public static boolean booleans_[] = new boolean[10];
    public static boolean subBooleans(boolean booleans[], int index){
        System.out.println("Java:" + Boolean.toString(booleans[index]));
        return booleans[index];
    }
    public static void updateBooleans(boolean booleans[], int index, boolean newValue){
        booleans[index] = newValue;
        System.out.println("Java:" + Boolean.toString(booleans[index]));
    }

    //////////

    public static byte bytes_[] = new byte[10];
    public static byte subBytes(byte bytes[], int index){
        System.out.println("Java:" + Byte.toString(bytes[index]));
        return bytes[index];
    }
    public static void updateBytes(byte bytes[], int index, byte newValue){
        bytes[index] = newValue;
        System.out.println("Java:" + Byte.toString(bytes[index]));
    }

    //////////

    public static char chars_[] = new char[10];
    public static char subChars(char chars[], int index){
        System.out.println("Java:" + Character.toString(chars[index]));
        return chars[index];
    }
    public static void updateChars(char chars[], int index, char newValue){
        chars[index] = newValue;
        System.out.println("Java:" + Character.toString(chars[index]));
    }

    //////////

    public static short shorts_[] = new short[10];
    public static short subShorts(short shorts[], int index){
        System.out.println("Java:" + Short.toString(shorts[index]));
        return shorts[index];
    }
    public static void updateShorts(short shorts[], int index, short newValue){
        shorts[index] = newValue;
        System.out.println("Java:" + Short.toString(shorts[index]));
    }

    //////////

    public static int ints_[] = new int[10];
    public static int subInts(int ints[], int index){
        System.out.println("Java:" + Integer.toString(ints[index]));
        return ints[index];
    }
    public static void updateInts(int ints[], int index, int newValue){
        ints[index] = newValue;
        System.out.println("Java:" + Integer.toString(ints[index]));
    }

    //////////

    public static long longs_[] = new long[10];
    public static long subLongs(long longs[], int index){
        System.out.println("Java:" + Long.toString(longs[index]));
        return longs[index];
    }
    public static void updateLongs(long longs[], int index, long newValue){
        longs[index] = newValue;
        System.out.println("Java:" + Long.toString(longs[index]));
    }

    //////////

    public static float floats_[] = new float[10];
    public static float subFloats(float floats[], int index){
        System.out.println("Java:" + Float.toString(floats[index]));
        return floats[index];
    }
    public static void updateFloats(float floats[], int index, float newValue){
        floats[index] = newValue;
        System.out.println("Java:" + Float.toString(floats[index]));
    }

    //////////

    public static double doubles_[] = new double[10];
    public static double subDoubles(double doubles[], int index){
        System.out.println("Java:" + Double.toString(doubles[index]));
        return doubles[index];
    }
    public static void updateDoubles(double doubles[], int index, double newValue){
        doubles[index] = newValue;
        System.out.println("Java:" + Double.toString(doubles[index]));
    }

    //////////

    public static Object objects_[] = new Object[10];
    public static Object subObjects(Object objects[], int index){
        System.out.println("Java:" + objects[index]);
        return objects[index];
    }
    public static void updateObjects(Object objects[], int index, Object newValue){
        objects[index] = newValue;
        System.out.println("Java:" + objects[index]);
    }

    //////////

}
