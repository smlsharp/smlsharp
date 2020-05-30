import java.util.concurrent.*;

class FibJavaForkJoin extends RecursiveTask<Integer> {

    static int repeat = 10;
    static int size = 40;
    static int cutOff = 10;

    static int fib(int n) {
        if (n <= 1) return n;
        else return fib(n - 1) + fib(n - 2);
    }

    static int fibp(int n) {
        if (n <= cutOff) return fib(n);
        ForkJoinTask<Integer> t = new FibJavaForkJoin(n - 1).fork();
        int r2 = fibp(n - 2);
        return t.join() + r2;
    }

    int arg;

    FibJavaForkJoin(int n) {
        arg = n;
    }

    protected Integer compute() {
        return fibp(arg);
    }

    static int doit(ForkJoinPool p) {
        return p.invoke(new FibJavaForkJoin(size));
    }

    static void rep(ForkJoinPool p) {
        for (int i = 0; i < repeat; i++) {
            long t1 = System.currentTimeMillis();
            int r = doit(p);
            long t2 = System.currentTimeMillis();
            System.out.println(" - {result: " + r + ", time: "
                               + (double)(t2 - t1) / 1000.0 + "}");
        }
    }

    public static void main(String[] args) {
        if (args.length > 0) repeat = Integer.parseInt(args[0]);
        if (args.length > 1) size = Integer.parseInt(args[1]);
        if (args.length > 2) cutOff = Integer.parseInt(args[2]);
        String nprocs = System.getenv("NPROCS");
        ForkJoinPool p = nprocs != null
                         ? new ForkJoinPool(Integer.parseInt(nprocs))
                         : new ForkJoinPool();
        System.out.println(" bench: fib_java_forkjoin");
        System.out.println(" size: " + size);
        System.out.println(" cutoff: " + cutOff);
        System.out.println(" results:");
        rep(p);
    }

}
