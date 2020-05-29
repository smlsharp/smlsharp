package main
import ( "fmt"; "os"; "strconv"; "time" )

var repeat = 10
var size = 40
var cutOff = 10

func fib(n int) int {
    if n <= 1 { return n } else { return fib (n - 1) + fib (n - 2) }
}

func fibp(n int) int {
    if n <= cutOff { return fib(n) }
    c := make(chan int)
    go func() { c <- fibp(n - 1) } ()
    n2 := fibp(n - 2)
    n1 := <-c
    return n1 + n2
}

func doit() int {
    return fibp(size)
}

func rep() {
  for i := 0; i < repeat; i++ {
    t1 := time.Now()
    r := doit()
    t2 := time.Now()
    fmt.Printf(" - {result: %d, time: %.6f}\n", r, t2.Sub(t1).Seconds())
  }
}

func main() {
  if len(os.Args) > 1 { repeat, _ = strconv.Atoi(os.Args[1]) }
  if len(os.Args) > 2 { size, _ = strconv.Atoi(os.Args[2]) }
  if len(os.Args) > 3 { cutOff, _ = strconv.Atoi(os.Args[3]) }
  fmt.Printf(" bench: fib_go_value\n size: %d\n cutoff: %d\n results:\n",
             size, cutOff);
  rep()
}
