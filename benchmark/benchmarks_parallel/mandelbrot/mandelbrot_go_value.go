package main
import ( "fmt"; "os"; "strconv"; "time" )

var repeat = 10
var size = 2048
var cutOff = 8
const x_base = -2.0
const y_base = 1.25
const side = 2.5
const maxCount = 1024
var delta float64 // = side / size
var image []uint8

func loopV(x int, y int, w int, h int) int {
  iterations := 0
  for i := 0; i < h; i++ {
    c_im := y_base - delta * float64(i + y)
    for j := 0; j < w; j++ {
      c_re := x_base + delta * float64(j + x)
      z_re := c_re
      z_im := c_im
      var count int
      for count = 0; count < maxCount; count++ {
        z_re_sq := z_re * z_re
        z_im_sq := z_im * z_im
        if z_re_sq + z_im_sq > 4.0 {
          image[j + x + size * (i + y)] = 1;
          break
        }
        re := z_re_sq - z_im_sq + c_re
        im := 2.0 * z_re * z_im + c_im
        z_re = re
        z_im = im
      }
      iterations += count
    }
  }
  return iterations
}

func mandelbrot (x int, y int, w int, h int) int {
  if w <= cutOff && h <= cutOff {
    return loopV(x, y, w, h)
  } else if w >= h {
    w2 := w / 2
    c := make(chan int)
    go func () { c <- mandelbrot(x + w2, y, w - w2, h) } ()
    r := mandelbrot(x, y, w2, h)
    return r + <- c
  } else {
    h2 := h / 2
    c := make(chan int)
    go func () { c <- mandelbrot(x, y + h2, w, h - h2) } ()
    r := mandelbrot(x, y, w, h2)
    return r + <- c
  }
}

func doit() int {
  return mandelbrot(0, 0, size, size)
}

func rep() {
  for i := 0; i < repeat; i++ {
    t1 := time.Now()
    r := doit()
    t2 := time.Now()
/*
    fmt.Fprintf(os.Stderr, "P1\n%d %d\n", size, size)
    for _, v := range image { fmt.Fprintf(os.Stderr, "%d", v) }
*/
    fmt.Printf(" - {result: %d, time: %.6f}\n", r, t2.Sub(t1).Seconds())
  }
}

func main() {
  if len(os.Args) > 1 { repeat, _ = strconv.Atoi(os.Args[1]) }
  if len(os.Args) > 2 { size, _ = strconv.Atoi(os.Args[2]) }
  if len(os.Args) > 3 { cutOff, _ = strconv.Atoi(os.Args[3]) }
  delta = side / float64(size)
  image = make([]uint8, size * size)
  fmt.Printf(" bench: mandelbrot_go_value\n size: %d\n cutoff: %d\n results:\n",
             size, cutOff);
  rep()
}
