package main
import ( "fmt"; "os"; "strconv"; "time" )

const MAXSIZE = 20
var repeat = 10
var size = 14
var cutOff = 7

type Board struct {
  Queens uint
  Limit uint
  Left uint
  Down uint
  Right uint
  Kill uint
}

func initBoard(width uint) Board {
  return Board {
    Queens: width,
    Limit: 1 << width,
    Left: 0,
    Down: 0,
    Right: 0,
    Kill: 0,
  }
}

func put (b Board, bit uint) Board {
  r := Board{}
  r.Queens = b.Queens - 1
  r.Limit = b.Limit
  r.Left = (b.Left | bit) >> 1
  r.Down = (b.Down | bit)
  r.Right = (b.Right | bit) << 1
  r.Kill = r.Left | r.Down | r.Right
  return r
}

func ssum (board Board) int {
  sum := 0
  var bit uint = 1
  for {
    if bit >= board.Limit { break }
    if (board.Kill & bit) == 0 { sum += solve(put(board, bit)) }
    bit <<= 1
  }
  return sum
}

func psum (board Board, bit uint) int {
  for {
    if bit >= board.Limit { break }
    if (board.Kill & bit) == 0 {
      t := make(chan int)
      go func(t chan int) { t <- solve(put(board, bit)) } (t)
      n := psum(board, bit << 1)
      return n + <- t
    }
    bit <<= 1
  }
  return 0
}

func solve (board Board) int {
  if board.Queens == 0 {
    return 1
  } else if board.Queens <= uint(cutOff) {
    return ssum(board)
  } else {
    return psum(board, 1)
  }
}

func doit() int {
    b := initBoard(uint(size))
    return solve(b)
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
  fmt.Printf(" bench: nqueen_go_value\n size: %d\n cutoff: %d\n results:\n",
             size, cutOff);
  rep()
}
