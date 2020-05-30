import GHC.Conc (par, pseq)
import Control.Exception (evaluate)
import System.Environment (getArgs)
import Data.Time.Clock (getCurrentTime, diffUTCTime)
import Data.Word (Word)
import Data.Bits

data Board =
  B {queens :: Int, limit :: Word,
     left :: Word, down :: Word, right :: Word, kill :: Word}

initBoard width =
  B {queens = width, limit = shiftL 1 width,
     left = 0, down = 0, right = 0, kill = 0}

put (B {queens=queens, limit=limit,
        left=left, down=down, right=right, kill=kill}) bit =
  B {queens = queens - 1, limit = limit,
     left = left', down = down', right = right', kill = kill'}
  where left' = shiftR (left .|. bit) 1
        down' = down .|. bit
        right' = shiftL (right .|. bit) 1
        kill' = left' .|. down' .|. right'

ssum cutOff board bit =
  if bit >= limit board then 0 :: Int
  else if kill board .&. bit == 0
  then solve cutOff (put board bit) + ssum cutOff board (shiftL bit 1)
  else ssum cutOff board (shiftL bit 1)

psum cutOff board bit =
  if bit >= limit board then 0 :: Int
  else if kill board .&. bit == 0
       then let t = solve cutOff (put board bit)
                n = psum cutOff board (shiftL bit 1)
            in t `par` n `pseq` t + n
       else psum cutOff board (shiftL bit 1)

solve cutOff board =
  if queens board == 0 then 1
  else if queens board <= cutOff
  then ssum cutOff board 1
  else psum cutOff board 1

doit cutOff size =
  solve cutOff (initBoard size)

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
     let size = case args of _:x:_ -> read x :: Int; otherwise -> 14
     let cutOff = case args of _:_:x:_ -> read x :: Int; otherwise -> 7
     putStrLn $ " bench: nqueen_ghc_par"
     putStrLn $ " size: " ++ show size
     putStrLn $ " cutoff: " ++ show cutOff
     putStrLn $ " results:"
     rep size cutOff repeat
