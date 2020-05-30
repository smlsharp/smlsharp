class MandelbrotJavaSeq {

    static int repeat = 10;
    static int size = 2048;
    static int cutOff = 8;
    static final double x_base = -2.0;
    static final double y_base = 1.25;
    static final double side = 2.5;
    static final int maxCount = 1024;
    static double delta; // = side / size
    static char image[];

    static int loopV(int x, int y, int w, int h)
    {
        int iterations = 0;
        int i, j, count;
        double c_re, c_im, z_re, z_im, z_re_sq, z_im_sq, re, im;
        for (i = 0; i < h; i++) {
            c_im = y_base - delta * (i + y);
            for (j = 0; j < w; j++) {
                c_re = x_base + delta * (j + x);
                z_re = c_re;
                z_im = c_im;
                for (count = 0; count < maxCount; count++) {
                    z_re_sq = z_re * z_re;
                    z_im_sq = z_im * z_im;
                    if (z_re_sq + z_im_sq > 4.0) {
                        image[j + x + size * (i + y)] = 1;
                        break;
                    }
                    re = z_re_sq - z_im_sq + c_re;
                    im = 2.0 * z_re * z_im + c_im;
                    z_re = re;
                    z_im = im;
                }
                iterations += count;
            }
        }
        return iterations;
    }

    static int mandelbrot(int x, int y, int w, int h)
    {
        if (w <= cutOff && h <= cutOff) {
            return loopV(x, y, w, h);
        } else if (w >= h) {
            int w2 = w / 2;
            int t = mandelbrot(x + w2, y, w - w2, h);
            int r = mandelbrot(x, y, w2, h);
            return r + t;
        } else {
            int h2 = h / 2;
            int t = mandelbrot(x, y + h2, w, h - h2);
            int r = mandelbrot(x, y, w, h2);
            return r + t;
        }
    }

    static int doit() {
        return mandelbrot(0, 0, size, size);
    }

    static void rep() {
        for (int i = 0; i < repeat; i++) {
            long t1 = System.currentTimeMillis();
            int r = doit();
            long t2 = System.currentTimeMillis();
/*
            System.err.println("P1\n" + size + " " + size);
            for (int i = 0; i < size * size; i++)
                System.err.print(image[i] + 0);
*/
            System.out.println(" - {result: " + r + ", time: "
                               + (double)(t2 - t1) / 1000.0 + "}");
        }
    }

    public static void main(String[] args) {
        if (args.length > 0) repeat = Integer.parseInt(args[0]);
        if (args.length > 1) size = Integer.parseInt(args[1]);
        if (args.length > 2) cutOff = Integer.parseInt(args[2]);
        delta = side / size;
        image = new char[size * size];
        System.out.println(" bench: mandelbrot_java_seq");
        System.out.println(" size: " + size);
        System.out.println(" cutoff: " + cutOff);
        System.out.println(" results:");
        rep();
    }

}
