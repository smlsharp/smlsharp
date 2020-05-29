import GHC.Conc (par, pseq)
import Control.Exception (evaluate)
import System.Environment (getArgs)
import Data.Time.Clock (getCurrentTime, diffUTCTime)

fib n | n <= 1 = n :: Int
fib n = fib (n - 1) + fib (n - 2)

fibp cutOff n | n <= cutOff = fib n
fibp cutOff n = let n1 = fibp cutOff (n - 1)
                    n2 = fibp cutOff (n - 2)
                in n1 `par` n2 `pseq` n1 + n2

doit cutOff size = fibp cutOff size

rep size cutOff 0 = return ()
rep size cutOff n =
  do t1 <- getCurrentTime
     r <- evaluate $ doit cutOff size
     t2 <- getCurrentTime
     putStrLn $ " - {result: " ++ show 0 ++ ", time: "
                ++ show (t2 `diffUTCTime` t1) ++ "}"
     rep size cutOff (n - 1)

main =
  do args <- getArgs
     let repeat = case args of x:_ -> read x :: Int; otherwise -> 10
     let size = case args of _:x:_ -> read x :: Int; otherwise -> 40
     let cutOff = case args of _:_:x:_ -> read x :: Int; otherwise -> 10
     putStrLn $ " bench: fib_ghc_par"
     putStrLn $ " size: " ++ show size
     putStrLn $ " cutoff: " ++ show cutOff
     putStrLn $ " results:"
     rep size cutOff repeat
