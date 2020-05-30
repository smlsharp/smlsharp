import java.util.concurrent.*;

class NqueenJavaForkJoin extends RecursiveTask<Integer> {

    static int repeat = 10;
    static int size = 14;
    static int cutOff = 7;

    static class Board {
        int queens, limit, left, down, right, kill;
    }

    static Board init(int width) {
        Board b = new Board();
        b.queens = width;
        b.limit = 1 << width;
        b.left = 0;
        b.down = 0;
        b.right = 0;
        b.kill = 0;
        return b;
    }

    static Board put(Board b, int bit) {
        Board r = new Board();
        r.queens = b.queens - 1;
        r.limit = b.limit;
        r.left = (b.left | bit) >> 1;
        r.down = b.down | bit;
        r.right = (b.right | bit) << 1;
        r.kill = r.left | r.down | r.right;
        return r;
    }

    static int ssum(Board board, int bit) {
        int sum = 0;
        while (bit < board.limit) {
            if ((board.kill & bit) == 0)
                sum += solve(put(board, bit));
            bit <<= 1;
        }
        return sum;
    }

    static int psum(Board board, int bit) {
        while (bit < board.limit) {
            if ((board.kill & bit) == 0) {
                ForkJoinTask<Integer> t =
                    new NqueenJavaForkJoin(put(board, bit)).fork();
                int n = psum(board, bit << 1);
                return n + t.join();
            }
            bit <<= 1;
        }
        return 0;
    }

    static int solve(Board board) {
        if (board.queens == 0) {
            return 1;
        } else if (board.queens <= cutOff) {
            return ssum(board, 1);
        } else {
            return psum(board, 1);
        }
    }

    Board arg;

    NqueenJavaForkJoin(Board board) {
      arg = board;
    }

    protected Integer compute() {
        return solve(arg);
    }

    static int doit(ForkJoinPool p) {
        return p.invoke(new NqueenJavaForkJoin(init(size)));
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
        System.out.println(" bench: nqueen_java_forkjoin");
        System.out.println(" size: " + size);
        System.out.println(" cutoff: " + cutOff);
        System.out.println(" results:");
        rep(p);
    }

}
