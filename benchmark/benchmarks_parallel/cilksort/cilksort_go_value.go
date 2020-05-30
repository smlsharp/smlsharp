package main
import ( "fmt"; "os"; "strconv"; "time" )

var repeat = 10
var size = 4194304
var cutOff = 32

func copy(a []float64, b int, e int, d []float64, j int) {
  for {
    if e < b { break }
    d[j] = a[b]
    j++
    b++
  }
}

func search(a []float64, b int, e int, k float64) int {
  for {
    if e < b { return e + 1 }
    if e == b { if k < a[e] { return e } else { return e + 1 } }
    m := (b + e) / 2
    x := a[m];
    if k < x { e = m } else { b = m + 1 }
  }
}

func merge(a []float64, b1 int, e1 int, b2 int, e2 int, d []float64, j int) {
  if e1 < b1 {
    copy(a, b2, e2, d, j)
  } else if e2 < b2 {
    copy(a, b1, e1, d, j)
  } else if e1 - b1 < e2 - b2 {
    merge(a, b2, e2, b1, e1, d, j)
  } else if a[e1] <= a[b2] {
    copy(a, b1, e1, d, j)
    copy(a, b2, e2, d, j+(e1-b1+1))
  } else if a[e2] <= a[b1] {
    copy(a, b2, e2, d, j)
    copy(a, b1, e1, d, j+(e2-b2+1))
  } else {
    m := (b1 + e1) / 2
    n := search(a, b2, e2, a[m])
    if e1 - b1 <= cutOff {
      merge(a, b1, m, b2, n-1, d, j)
      merge(a, m+1, e1, n, e2, d, j+(m-b1+1)+(n-b2))
    } else {
      c := make(chan int)
      go func () { merge(a, b1, m, b2, n-1, d, j); c <- 0 } ()
      merge(a, m+1, e1, n, e2, d, j+(m-b1+1)+(n-b2))
      <- c
    }
  }
}

func cilksort(a []float64, b int, e int, d []float64, j int) {
  if e <= b { return }
  q2 := (b + e) / 2
  q1 := (b + q2) / 2
  q3 := (q2+1 + e) / 2
  if e - b <= cutOff {
    cilksort(a, b, q1, d, j)
    cilksort(a, q1+1, q2, d, j+(q1-b+1))
    cilksort(a, q2+1, q3, d, j+(q2-b+1))
    cilksort(a, q3+1, e, d, j+(q3-b+1))
    merge(a, b, q1, q1+1, q2, d, j)
    merge(a, q2+1, q3, q3+1, e, d, j+(q2-b+1))
    merge(d, b, q2, q2+1, e, a, b)
  } else {
    c1 := make(chan int)
    go func () {
      c := make(chan int)
      go func () { cilksort(a, b, q1, d, j); c <- 0 } ()
      cilksort(a, q1+1, q2, d, j+(q1-b+1))
      <- c
      merge(a, b, q1, q1+1, q2, d, j)
      c1 <- 0
    } ()
    c2 := make(chan int)
    go func () { cilksort(a, q2+1, q3, d, j+(q2-b+1)); c2 <- 0 } ()
    cilksort(a, q3+1, e, d, j+(q3-b+1))
    <- c2
    merge(a, q2+1, q3, q3+1, e, d, j+(q2-b+1))
    <- c1
    merge(d, b, q2, q2+1, e, a, b)
  }
}

var pmseed = 1

func pmrand() int {
  hi := pmseed / (2147483647 / 48271)
  lo := pmseed % (2147483647 / 48271)
  test := 48271 * lo - (2147483647 % 48271) * hi
  if test > 0 { pmseed = test } else { pmseed = test + 2147483647 }
  return pmseed
}

func randReal() float64 {
  d1 := float64(pmrand())
  d2 := float64(pmrand())
  return d1 / d2
}

func init_a() []float64 {
  a := make([]float64, size)
  pmseed = 1;
  for i, _ := range a { a[i] = randReal() }
  return a
}

func init_d() []float64 {
  return make([]float64, size)
}

func doit(a []float64, d []float64) {
  cilksort(a, 0, size - 1, d, 0)
}

func rep() {
  for i := 0; i < repeat; i++ {
    a := init_a()
    d := init_d()
    t1 := time.Now()
    doit(a, d)
    t2 := time.Now()
/*
    for _, v := range a { fmt.Fprintf(os.Stderr, "%f\n", v) }
*/
    fmt.Printf(" - {result: %d, time: %.6f}\n", 0, t2.Sub(t1).Seconds())
  }
}

func main() {
  if len(os.Args) > 1 { repeat, _ = strconv.Atoi(os.Args[1]) }
  if len(os.Args) > 2 { size, _ = strconv.Atoi(os.Args[2]) }
  if len(os.Args) > 3 { cutOff, _ = strconv.Atoi(os.Args[3]) }
  fmt.Printf(" bench: cilksort_go_value\n size: %d\n cutoff: %d\n results:\n",
             size, cutOff);
  rep()
}
