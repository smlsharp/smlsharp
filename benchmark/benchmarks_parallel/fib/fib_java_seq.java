class FibJavaSeq {

    static int repeat = 10;
    static int size = 40;
    static int cutOff = 10;

    static int fib(int n) {
        if (n <= 1) return n;
        else return fib(n - 1) + fib(n - 2);
    }

    static int fibp(int n) {
        if (n <= cutOff) return fib(n);
        int t = fibp(n - 1);
        int r2 = fibp(n - 2);
        return t + r2;
    }

    static int doit() {
        return fibp(size);
    }

    static void rep() {
        for (int i = 0; i < repeat; i++) {
            long t1 = System.currentTimeMillis();
            int r = doit();
            long t2 = System.currentTimeMillis();
            System.out.println(" - {result: " + r + ", time: "
                               + (double)(t2 - t1) / 1000.0 + "}");
        }
    }

    public static void main(String[] args) {
        if (args.length > 0) repeat = Integer.parseInt(args[0]);
        if (args.length > 1) size = Integer.parseInt(args[1]);
        if (args.length > 2) cutOff = Integer.parseInt(args[2]);
        System.out.println(" bench: fib_java_seq");
        System.out.println(" size: " + size);
        System.out.println(" cutoff: " + cutOff);
        System.out.println(" results:");
        rep();
    }

}
