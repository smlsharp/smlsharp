class CilksortJavaSeq {

    static int repeat = 10;
    static int size = 4194304;
    static int cutOff = 32;

    static void copy(double[] a, int b, int e, double[] d, int j)
    {
        while (e >= b)
            d[j++] = a[b++];
    }

    static int search(double[] a, int b, int e, double k)
    {
        for (;;) {
            if (e < b) return e + 1;
            if (e == b) return k < a[e] ? e : e + 1;
            int m = (b + e) / 2;
            if (k < a[m])
                e = m;
            else
                b = m + 1;
        }
    }

    static void merge(double[] a, int b1, int e1, int b2, int e2,
                      double[] d, int j)
    {
        if (e1 < b1)
            copy(a, b2, e2, d, j);
        else if (e2 < b2)
            copy(a, b1, e1, d, j);
        else if (e1 - b1 < e2 - b2)
            merge(a, b2, e2, b1, e1, d, j);
        else if (a[e1] <= a[b2]) {
            copy(a, b1, e1, d, j);
            copy(a, b2, e2, d, j+(e1-b1+1));
        } else if (a[e2] <= a[b1]) {
            copy(a, b2, e2, d, j);
            copy(a, b1, e1, d, j+(e2-b2+1));
        } else {
            int m = (b1 + e1) / 2;
            int n = search(a, b2, e2, a[m]);
            if (e1 - b1 <= cutOff) {
                merge(a, b1, m, b2, n-1, d, j);
                merge(a, m+1, e1, n, e2, d, j+(m-b1+1)+(n-b2));
            } else {
                merge(a, b1, m, b2, n-1, d, j);
                merge(a, m+1, e1, n, e2, d, j+(m-b1+1)+(n-b2));
            }
        }
    }

    static void cilksort(double[] a, int b, int e, double[] d, int j)
    {
        if (e <= b) return;
        int q2 = (b + e) / 2;
        int q1 = (b + q2) / 2;
        int q3 = (q2+1 + e) / 2;
        if (e - b <= cutOff) {
            cilksort(a, b, q1, d, j);
            cilksort(a, q1+1, q2, d, j+(q1-b+1));
            cilksort(a, q2+1, q3, d, j+(q2-b+1));
            cilksort(a, q3+1, e, d, j+(q3-b+1));
            merge(a, b, q1, q1+1, q2, d, j);
            merge(a, q2+1, q3, q3+1, e, d, j+(q2-b+1));
            merge(d, b, q2, q2+1, e, a, b);
        } else {
            sortmerge(a, b, q1, q2, d, j);
            cilksort(a, q2+1, q3, d, j+(q2-b+1));
            cilksort(a, q3+1, e, d, j+(q3-b+1));
            merge(a, q2+1, q3, q3+1, e, d, j+(q2-b+1));
            merge(d, b, q2, q2+1, e, a, b);
        }
    }

    static void sortmerge(double[] a, int b, int q1, int q2, double[] d, int j)
    {
        cilksort(a, b, q1, d, j);
        cilksort(a, q1+1, q2, d, j+(q1-b+1));
        merge(a, b, q1, q1+1, q2, d, j);
    }

    static int pmseed = 1;

    static int pmrand()
    {
        int hi = pmseed / (2147483647 / 48271);
        int lo = pmseed % (2147483647 / 48271);
        int test = 48271 * lo - (2147483647 % 48271) * hi;
        pmseed = (int)test > 0 ? test : test + 2147483647;
        return pmseed;
    }

    static double randReal()
    {
        double d1 = pmrand();
        double d2 = pmrand();
        return d1 / d2;
    }

    static double[] init_a()
    {
        double[] a = new double[size];
	pmseed = 1;
	for (int i = 0; i < size; i++) a[i] = randReal();
	return a;
    }

    static double[] init_d()
    {
        return new double[size];
    }

    static void doit(double[] a, double[] d) {
        cilksort(a, 0, size - 1, d, 0);
    }

    static void rep() {
        for (int i = 0; i < repeat; i++) {
            double[] a = init_a();
            double[] d = init_d();
            long t1 = System.currentTimeMillis();
            doit(a, d);
            long t2 = System.currentTimeMillis();
/*
            for (int j = 0; j < size; j++)
                System.err.println(a[j]);
*/
            System.out.println(" - {result: 0, time: "
                               + (double)(t2 - t1) / 1000.0 + "}");
        }
    }

    public static void main(String[] args) {
        if (args.length > 0) repeat = Integer.parseInt(args[0]);
        if (args.length > 1) size = Integer.parseInt(args[1]);
        if (args.length > 2) cutOff = Integer.parseInt(args[2]);
        System.out.println(" bench: cilksort_java_seq");
        System.out.println(" size: " + size);
        System.out.println(" cutoff: " + cutOff);
        System.out.println(" results:");
        rep();
    }

}
